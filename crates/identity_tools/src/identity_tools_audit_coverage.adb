with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

package body Identity_Tools_Audit_Coverage is
   use Ada.Strings.Unbounded;

   Max_Primitives : constant := 256;

   type Name_Array is array (1 .. Max_Primitives) of Unbounded_String;

   function Resolve (Relative : String) return String is
     (if Ada.Directories.Exists (Relative) then Relative else "../../" & Relative);

   function Interface_Path return String is
     (Resolve ("src/adapters/identity-adapters-repositories-stores.ads"));

   function Operations_Dir return String is
     (Resolve ("src/public"));

   function Exemptions_Path return String is
     (Resolve ("registries/audit-exemptions.json"));

   function Contains (Text : String; Pattern : String) return Boolean is
     (Ada.Strings.Fixed.Index (Text, Pattern) /= 0);

   function Load (Path : String) return String is
      File   : Ada.Text_IO.File_Type;
      Buffer : Unbounded_String;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Append (Buffer, Ada.Text_IO.Get_Line (File));
         Append (Buffer, ' ');
      end loop;
      Ada.Text_IO.Close (File);
      return To_String (Buffer);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Load;

   --  Collect the names of primitives declared with "Repository : in out
   --  Store_Interface" -- the ones that can change stored state.
   --  Collapse runs of spaces to one. The SPI aligns parameter colons, so a
   --  fixed-spacing search matched only the declarations that happened to use
   --  a single space -- 40 of 55 -- and every operation mutating only through
   --  one of the other 15 was silently scored as non-mutating.
   function Collapsed (Text : String) return String is
      Result : String (1 .. Text'Length);
      Last   : Natural := 0;
      Space  : Boolean := False;
   begin
      for Ch of Text loop
         if Ch = ' ' or else Ch = ASCII.HT then
            Space := True;
         else
            if Space and then Last > 0 then
               Last := Last + 1;
               Result (Last) := ' ';
            end if;
            Space := False;
            Last := Last + 1;
            Result (Last) := Ch;
         end if;
      end loop;
      return Result (1 .. Last);
   end Collapsed;

   procedure Collect_Mutating
     (Names : out Name_Array;
      Count : out Natural)
   is
      Text   : constant String := Collapsed (Load (Interface_Path));
      Cursor : Natural := Text'First;
      Marker : constant String := "Repository : in out Store_Interface";
   begin
      Names := [others => Null_Unbounded_String];
      Count := 0;

      loop
         declare
            Hit : constant Natural :=
              Ada.Strings.Fixed.Index (Text (Cursor .. Text'Last), Marker);
         begin
            exit when Hit = 0;

            --  Walk back to the subprogram name that introduces this profile.
            declare
               Open_Paren : Natural := Hit;
               Name_Last  : Natural;
               Name_First : Natural;
            begin
               while Open_Paren > Text'First and then Text (Open_Paren) /= '(' loop
                  Open_Paren := Open_Paren - 1;
               end loop;

               Name_Last := Open_Paren - 1;
               while Name_Last > Text'First and then Text (Name_Last) = ' ' loop
                  Name_Last := Name_Last - 1;
               end loop;

               Name_First := Name_Last;
               while Name_First > Text'First
                 and then (Text (Name_First - 1) in 'A' .. 'Z' | 'a' .. 'z'
                           | '0' .. '9' | '_')
               loop
                  Name_First := Name_First - 1;
               end loop;

               if Name_Last >= Name_First and then Count < Max_Primitives then
                  declare
                     Name : constant String := Text (Name_First .. Name_Last);
                     Seen : Boolean := False;
                  begin
                     for Index in 1 .. Count loop
                        if To_String (Names (Index)) = Name then
                           Seen := True;
                        end if;
                     end loop;
                     if not Seen and then Name'Length > 2 then
                        Count := Count + 1;
                        Names (Count) := To_Unbounded_String (Name);
                     end if;
                  end;
               end if;
            end;

            Cursor := Hit + Marker'Length;
            exit when Cursor > Text'Last;
         end;
      end loop;
   end Collect_Mutating;

   procedure Validate (Report : out Validation_Report) is
      Exemptions : constant String :=
        (if Ada.Directories.Exists (Exemptions_Path)
         then Load (Exemptions_Path) else "");
      Names  : Name_Array;
      Count  : Natural;
      Search : Ada.Directories.Search_Type;
      Item   : Ada.Directories.Directory_Entry_Type;
   begin
      Report := (others => 0);

      if not Ada.Directories.Exists (Interface_Path)
        or else not Ada.Directories.Exists (Operations_Dir)
      then
         Report.Missing_Source := 1;
         Ada.Text_IO.Put_Line ("audit-coverage:missing-source");
         return;
      end if;

      Collect_Mutating (Names, Count);
      Report.Mutating_Primitives := Count;

      Ada.Directories.Start_Search
        (Search, Operations_Dir, "*.adb",
         [Ada.Directories.Ordinary_File => True, others => False]);
      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Item);
         declare
            Simple : constant String := Ada.Directories.Simple_Name (Item);
         begin
            if Simple'Length > 20
              and then Simple (Simple'First .. Simple'First + 19) =
                         "identity-operations-"
              --  The audit helper performs the emission; it is not itself an
              --  operation that has to be audited.
              and then Simple /= "identity-operations-audit.adb"
            then
               declare
                  Body_Text : constant String :=
                    Load (Ada.Directories.Full_Name (Item));
                  Mutates : Boolean := False;
               begin
                  for Index in 1 .. Count loop
                     if Contains (Body_Text, "Stores." & To_String (Names (Index)))
                     then
                        Mutates := True;
                     end if;
                  end loop;

                  if Mutates then
                     Report.Mutating_Operations := Report.Mutating_Operations + 1;
                     if Contains (Body_Text, "Audit.Emit") then
                        Report.Audited_Operations := Report.Audited_Operations + 1;
                     elsif Contains (Exemptions, """" & Simple & """") then
                        --  Exempt, but only if it states why and what covers it.
                        Report.Exemptions := Report.Exemptions + 1;
                        if not Contains (Exemptions, """reason""")
                          or else not Contains
                                       (Exemptions, """compensating_control""")
                        then
                           Report.Unjustified_Exemptions :=
                             Report.Unjustified_Exemptions + 1;
                           Ada.Text_IO.Put_Line
                             ("audit-coverage:unjustified-exemption:" & Simple);
                        end if;
                     else
                        Report.Unaudited_Operations :=
                          Report.Unaudited_Operations + 1;
                        Ada.Text_IO.Put_Line
                          ("audit-coverage:unaudited-operation:" & Simple);
                     end if;
                  end if;
               end;
            end if;
         end;
      end loop;
      Ada.Directories.End_Search (Search);

      --  Second pass over the specs: how many Execute overloads take an
      --  operation context (audited) and how many do not (bypass surface).
      Ada.Directories.Start_Search
        (Search, Operations_Dir, "*.ads",
         [Ada.Directories.Ordinary_File => True, others => False]);
      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Item);
         declare
            Simple : constant String := Ada.Directories.Simple_Name (Item);
         begin
            if Simple'Length > 20
              and then Simple (Simple'First .. Simple'First + 19) =
                         "identity-operations-"
              and then Simple /= "identity-operations-audit.ads"
            then
               declare
                  Spec   : constant String :=
                    Load (Ada.Directories.Full_Name (Item));
                  Cursor : Natural := Spec'First;
                  Marker : constant String := "Execute";
               begin
                  loop
                     declare
                        Hit : constant Natural :=
                          Ada.Strings.Fixed.Index
                            (Spec (Cursor .. Spec'Last), Marker);
                        Stop : Natural;
                     begin
                        exit when Hit = 0;
                        Stop := Ada.Strings.Fixed.Index
                          (Spec (Hit .. Spec'Last), ";");
                        if Stop = 0 then
                           Stop := Spec'Last;
                        end if;
                        --  Look ahead to the end of this declaration for the
                        --  context parameter that marks an audited overload.
                        declare
                           Window_Last : constant Natural :=
                             Natural'Min (Spec'Last, Hit + 600);
                           Window : constant String := Spec (Hit .. Window_Last);
                        begin
                           if Contains (Window, "Operation_Context") then
                              Report.Audited_Overloads :=
                                Report.Audited_Overloads + 1;
                           else
                              Report.Bypass_Overloads :=
                                Report.Bypass_Overloads + 1;
                           end if;
                        end;
                        Cursor := Hit + Marker'Length;
                        exit when Cursor > Spec'Last;
                     end;
                  end loop;
               end;
            end if;
         end;
      end loop;
      Ada.Directories.End_Search (Search);
   end Validate;

   function Passed (Report : Validation_Report) return Boolean is
     (Report.Missing_Source = 0
      and then Report.Mutating_Primitives > 0
      and then Report.Mutating_Operations > 0
      and then Report.Unaudited_Operations = 0
      and then Report.Unjustified_Exemptions = 0);

end Identity_Tools_Audit_Coverage;
