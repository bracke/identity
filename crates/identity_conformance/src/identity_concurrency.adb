with Ada.Command_Line;
with Ada.Text_IO;
with Identity.Adapters.Repositories.Capabilities;
with Identity.Adapters.Repositories.Memory;
with Identity.Adapters.Repositories.Serialized;
with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers;
with Identity.Identifiers.Entities;
with Identity.Principals.Definitions;
with Identity.Principals.Kinds;

--  Concurrency suite.
--
--  The reference memory adapter is deliberately not task-safe, so this suite
--  does not race it. It exercises the supported concurrent path instead: the
--  Serialized decorator, which serialises every SPI call through one lock.
--
--  Under contention the store must stay internally consistent -- every command
--  either applies or is rejected, never both and never partially -- so the
--  invariants below are exact, not statistical.
procedure Identity_Concurrency is

   package Memory renames Identity.Adapters.Repositories.Memory;
   package Stores renames Identity.Adapters.Repositories.Stores;
   package Serialized renames Identity.Adapters.Repositories.Serialized;
   package Caps renames Identity.Adapters.Repositories.Capabilities;

   use type Stores.Command_Status;
   use type Identity.Principals.Definitions.Principal_Lifecycle;

   Task_Count       : constant := 16;
   --  Bounded by Memory.Max_Principals: every identifier must fit, so that a
   --  non-Applied outcome can only mean a uniqueness conflict.
   Per_Task         : constant := 64;
   Total_Attempts   : constant := Task_Count * Per_Task;

   type Store_Access is access Memory.Store;

   --  Heap-allocated: a Memory.Store is a large fixed-capacity record.
   Backing : constant Store_Access := new Memory.Store;
   Shared  : aliased Serialized.Store
     (Inner => Stores.Store_Interface'Class (Backing.all)'Access);

   --  Every call below goes through the class-wide view, so the workers
   --  exercise the SPI exactly as the operations layer does.
   View : Stores.Store_Interface'Class renames
     Stores.Store_Interface'Class (Shared);

   Failures : Natural := 0;

   procedure Check (Outcome : Boolean; Label : String) is
   begin
      if Outcome then
         Ada.Text_IO.Put_Line ("identity_concurrency:" & Label & ":passed");
      else
         Ada.Text_IO.Put_Line ("identity_concurrency:" & Label & ":failed");
         Failures := Failures + 1;
      end if;
   end Check;

   function Count_Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);
   end Count_Image;

   function Principal_Of (Index : Natural) return
     Identity.Identifiers.Entities.Principal_Id
   is
      Digits_Text : constant String := Count_Image (Index);
      Padded      : String (1 .. 4) := "0000";
   begin
      Padded (Padded'Last - Digits_Text'Length + 1 .. Padded'Last) := Digits_Text;
      return Identity.Identifiers.Entities.Principal
        (Identity.Identifiers.From_String
           ("00000000-0000-0000-0000-00000000" & Padded));
   end Principal_Of;

   function Active_Principal (Index : Natural)
     return Identity.Principals.Definitions.Principal_Record is
     (Id      => Principal_Of (Index),
      Kind    => Identity.Principals.Kinds.Human,
      State   => Identity.Principals.Definitions.Active,
      Version => 0);

   --  Every worker attempts the SAME set of identifiers. Exactly one attempt
   --  per identifier may be Applied; the rest must be Uniqueness_Conflict.
   --  A lost update or a torn write shows up as a wrong tally.
   protected Tally is
      procedure Record_Outcome (Status : Stores.Command_Status);
      function Applied_Count return Natural;
      function Conflict_Count return Natural;
      function Other_Count return Natural;
   private
      Applied   : Natural := 0;
      Conflicts : Natural := 0;
      Others_Seen : Natural := 0;
   end Tally;

   protected body Tally is
      procedure Record_Outcome (Status : Stores.Command_Status) is
      begin
         if Status = Stores.Applied then
            Applied := Applied + 1;
         elsif Status = Stores.Uniqueness_Conflict then
            Conflicts := Conflicts + 1;
         else
            Others_Seen := Others_Seen + 1;
         end if;
      end Record_Outcome;

      function Applied_Count return Natural is (Applied);
      function Conflict_Count return Natural is (Conflicts);
      function Other_Count return Natural is (Others_Seen);
   end Tally;

   task type Worker is
      entry Start;
   end Worker;

   task body Worker is
   begin
      accept Start;
      for Index in 1 .. Per_Task loop
         Tally.Record_Outcome
           (Stores.Create_Principal (View, Active_Principal (Index)));
      end loop;
   end Worker;

begin
   Stores.Reset (View);

   Check (Caps.Repository_Capabilities'(Memory.Capabilities).Concurrent_Access = False,
          "memory-adapter-declares-no-concurrent-access");
   Check (Stores.Capabilities (View).Concurrent_Access,
          "serialized-adapter-declares-concurrent-access");

   declare
      Workers : array (1 .. Task_Count) of Worker;
   begin
      for W of Workers loop
         W.Start;
      end loop;
   end;

   --  Exactly Per_Task identifiers exist, so exactly that many creations may
   --  have succeeded no matter how the tasks interleaved.
   Check (Tally.Applied_Count = Per_Task,
          "exactly-one-create-succeeds-per-identifier");
   Check (Tally.Conflict_Count = Total_Attempts - Per_Task,
          "every-other-attempt-is-a-uniqueness-conflict");
   Check (Tally.Other_Count = 0,
          "no-attempt-produced-an-unexpected-status");
   Check (Stores.Principal_Count (View) = Per_Task,
          "store-holds-exactly-the-created-principals");

   --  Each surviving principal must be individually readable and intact: a
   --  torn write would leave a slot present but not resolvable.
   declare
      Intact : Natural := 0;
      Found  : Boolean;
      Record_Value : Identity.Principals.Definitions.Principal_Record;
   begin
      for Index in 1 .. Per_Task loop
         Stores.Find_Principal (View, Principal_Of (Index), Found, Record_Value);
         if Found
           and then Record_Value.State = Identity.Principals.Definitions.Active
         then
            Intact := Intact + 1;
         end if;
      end loop;
      Check (Intact = Per_Task, "every-stored-principal-is-readable-and-active");
   end;

   Ada.Text_IO.Put_Line
     ("identity_concurrency:tasks:" & Count_Image (Task_Count)
      & ":attempts:" & Count_Image (Total_Attempts)
      & ":applied:" & Count_Image (Tally.Applied_Count)
      & ":conflicts:" & Count_Image (Tally.Conflict_Count));

   if Failures = 0 then
      Ada.Text_IO.Put_Line ("identity_concurrency:result:passed");
   else
      Ada.Text_IO.Put_Line ("identity_concurrency:result:failed");
      Ada.Command_Line.Set_Exit_Status (1);
   end if;
end Identity_Concurrency;
