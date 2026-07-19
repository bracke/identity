with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

package body Identity_Tools_Capabilities is
   use Ada.Strings.Unbounded;

   function Resolve (Relative : String) return String is
     (if Ada.Directories.Exists (Relative) then Relative else "../../" & Relative);

   function Profile_Path return String is
     (Resolve ("src/adapters/identity-adapters-repositories-capabilities.adb"));

   function Operations_Dir return String is
     (Resolve ("src/public"));

   function Contains (Text : String; Pattern : String) return Boolean is
     (Ada.Strings.Fixed.Index (Text, Pattern) /= 0);

   --  Each advertised capability names the SPI primitive that backs it. A
   --  capability is honoured only when the operations layer actually calls
   --  that primitive.
   type Capability_Id is
     (Security_Transitions,
      Atomic_Mandatory_Events,
      Optimistic_Versions,
      Atomic_Session_Rotation,
      Atomic_Token_Action,
      Session_Family_Revocation,
      Assertion_Replay_Registration,
      Idempotency,
      Deterministic_Event_Ordering);

   function Flag_Name (Id : Capability_Id) return String is
     (case Id is
        when Security_Transitions          => "Security_Transitions",
        when Atomic_Mandatory_Events       => "Atomic_Mandatory_Events",
        when Optimistic_Versions           => "Optimistic_Versions",
        when Atomic_Session_Rotation       => "Atomic_Session_Rotation",
        when Atomic_Token_Action           => "Atomic_Token_Action",
        when Session_Family_Revocation     => "Session_Family_Revocation",
        when Assertion_Replay_Registration => "Assertion_Replay_Registration",
        when Idempotency                   => "Idempotency",
        when Deterministic_Event_Ordering  => "Deterministic_Event_Ordering");

   --  The primitive whose presence in the operations layer proves the flag.
   function Backing_Primitive (Id : Capability_Id) return String is
     (case Id is
        when Security_Transitions          => "Retire_Principal",
        when Atomic_Mandatory_Events       => "Append_Event",
        when Optimistic_Versions           => "Expected_Version",
        when Atomic_Session_Rotation       => "Rotate_Session",
        when Atomic_Token_Action           => "Consume_Token",
        when Session_Family_Revocation     => "Revoke_Session_Family",
        --  Replay registration happens inside the store's Authenticate_External,
        --  so the operation-visible primitive is what proves it is exercised.
        when Assertion_Replay_Registration => "Authenticate_External",
        when Idempotency                   => "Reserve_Idempotency",
        when Deterministic_Event_Ordering  => "Append_Event");

   --  Capabilities that must additionally be reserved before mutating; an
   --  event appended after the fact is not atomic with its transition.
   function Requires_Reservation (Id : Capability_Id) return Boolean is
     (Id = Atomic_Mandatory_Events);

   Reservation_Primitive : constant String := "Event_Capacity_Available";

   --  Concatenate every operations-layer body into one searchable string.
   function Load_Operations (Found : out Boolean) return String is
      Search : Ada.Directories.Search_Type;
      Item   : Ada.Directories.Directory_Entry_Type;
      Buffer : Unbounded_String;
   begin
      Found := Ada.Directories.Exists (Operations_Dir);
      if not Found then
         return "";
      end if;

      Ada.Directories.Start_Search
        (Search, Operations_Dir, "*.adb",
         [Ada.Directories.Ordinary_File => True, others => False]);
      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Item);
         declare
            Name : constant String := Ada.Directories.Simple_Name (Item);
         begin
            --  Only the operations layer counts. The audit helper is part of
            --  that layer; adapters are not, or every capability would look
            --  backed by the adapter that declares it.
            if Name'Length > 20
              and then Name (Name'First .. Name'First + 19) = "identity-operations-"
            then
               declare
                  File : Ada.Text_IO.File_Type;
               begin
                  Ada.Text_IO.Open
                    (File, Ada.Text_IO.In_File, Ada.Directories.Full_Name (Item));
                  while not Ada.Text_IO.End_Of_File (File) loop
                     Append (Buffer, Ada.Text_IO.Get_Line (File));
                     Append (Buffer, ' ');
                  end loop;
                  Ada.Text_IO.Close (File);
               end;
            end if;
         end;
      end loop;
      Ada.Directories.End_Search (Search);
      return To_String (Buffer);
   end Load_Operations;

   --  Read the advertised profile: a flag is advertised when Full_Memory_Profile
   --  sets it True.
   function Advertised_True (Profile : String; Id : Capability_Id) return Boolean is
      Marker : constant String := Flag_Name (Id);
      Index  : constant Natural := Ada.Strings.Fixed.Index (Profile, Marker);
   begin
      if Index = 0 then
         return False;
      end if;
      declare
         Tail_Last : constant Natural :=
           Natural'Min (Profile'Last, Index + Marker'Length + 40);
         Tail : constant String := Profile (Index .. Tail_Last);
      begin
         return Contains (Tail, "=> True");
      end;
   end Advertised_True;

   procedure Validate (Report : out Validation_Report) is
      Have_Ops : Boolean;
      Profile  : Unbounded_String;
   begin
      Report := (others => 0);

      if not Ada.Directories.Exists (Profile_Path) then
         Report.Missing_Source := 1;
         Ada.Text_IO.Put_Line ("capabilities:missing-profile:" & Profile_Path);
         return;
      end if;

      declare
         File : Ada.Text_IO.File_Type;
      begin
         Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Profile_Path);
         while not Ada.Text_IO.End_Of_File (File) loop
            Append (Profile, Ada.Text_IO.Get_Line (File));
            Append (Profile, ' ');
         end loop;
         Ada.Text_IO.Close (File);
      end;

      declare
         Operations : constant String := Load_Operations (Have_Ops);
         Profile_Text : constant String := To_String (Profile);
      begin
         if not Have_Ops then
            Report.Missing_Source := Report.Missing_Source + 1;
            Ada.Text_IO.Put_Line
              ("capabilities:missing-operations:" & Operations_Dir);
            return;
         end if;

         for Id in Capability_Id loop
            if Advertised_True (Profile_Text, Id) then
               Report.Advertised := Report.Advertised + 1;

               declare
                  Backed : Boolean :=
                    Contains (Operations, Backing_Primitive (Id));
               begin
                  if Backed and then Requires_Reservation (Id) then
                     Backed := Contains (Operations, Reservation_Primitive);
                     if not Backed then
                        Ada.Text_IO.Put_Line
                          ("capabilities:unreserved:" & Flag_Name (Id)
                           & ":" & Reservation_Primitive);
                     end if;
                  end if;

                  if Backed then
                     Report.Backed := Report.Backed + 1;
                  else
                     Report.Unbacked := Report.Unbacked + 1;
                     Ada.Text_IO.Put_Line
                       ("capabilities:advertised-but-unbacked:" & Flag_Name (Id)
                        & ":" & Backing_Primitive (Id));
                  end if;
               end;
            end if;
         end loop;
      end;
   end Validate;

   function Passed (Report : Validation_Report) return Boolean is
     (Report.Missing_Source = 0
      and then Report.Advertised > 0
      and then Report.Unbacked = 0);

end Identity_Tools_Capabilities;
