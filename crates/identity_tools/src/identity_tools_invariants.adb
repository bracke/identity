with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

package body Identity_Tools_Invariants is
   use Ada.Strings.Unbounded;

   function Is_Space (Value : Character) return Boolean is
     (Value = ' ' or else Value = Character'Val (9));

   function Trimmed (Line : String) return String is
      First : Natural := Line'First;
      Last  : Natural := Line'Last;
   begin
      while First <= Line'Last and then Is_Space (Line (First)) loop
         First := First + 1;
      end loop;

      while Last >= First and then Is_Space (Line (Last)) loop
         Last := Last - 1;
      end loop;

      if First > Line'Last or else Last < First then
         return "";
      end if;

      return Line (First .. Last);
   end Trimmed;

   function Resolve (Relative : String) return String is
     (if Ada.Directories.Exists (Relative) then Relative else "../../" & Relative);

   function Registry_Path return String is
     (Resolve ("registries/invariants.json"));

   --  Evidence sources a required_tests name may be satisfied by. Behavioural
   --  invariants are asserted in the AUnit suite; gate-level invariants ("the
   --  tool fails when X is missing") are asserted by the gate self-test
   --  harness, and profile certification by the conformance harness. A name
   --  counts as traced when it appears verbatim in at least one of them.
   type Evidence_Source is (Test_Suite, Gate_Self_Tests, Conformance, Examples);

   function Evidence_Path (Source : Evidence_Source) return String is
     (case Source is
        when Test_Suite =>
          Resolve ("crates/identity_tests/src/identity_tests_cases.adb"),
        when Gate_Self_Tests =>
          Resolve ("crates/identity_gate_selftests/src/gate_selftests.adb"),
        when Conformance =>
          Resolve ("crates/identity_conformance/src/identity_conformance.adb"),
        when Examples =>
          Resolve ("crates/identity_examples/src/identity_lifecycle.adb"));

   ---------------------------------------------------------------------------
   --  Test-source normalisation
   ---------------------------------------------------------------------------

   --  Load the suite as a single line with runs of whitespace collapsed, then
   --  splice Ada string concatenations ("... " & "...") back together, so a
   --  registry name still matches when the assertion message is wrapped
   --  across source lines.
   function Load_Normalized (Path : String; Found : out Boolean) return String is
      File   : Ada.Text_IO.File_Type;
      Buffer : Unbounded_String;
   begin
      Found := Ada.Directories.Exists (Path);
      if not Found then
         return "";
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Text : constant String := Trimmed (Ada.Text_IO.Get_Line (File));
         begin
            if Length (Buffer) > 0 then
               Append (Buffer, ' ');
            end if;
            Append (Buffer, Text);
         end;
      end loop;
      Ada.Text_IO.Close (File);

      declare
         Raw    : constant String := To_String (Buffer);
         Result : String (1 .. Raw'Length);
         Last   : Natural := 0;
         Index  : Natural := Raw'First;
         Splice : constant String := """ & """;
         Space  : Boolean := False;
      begin
         while Index <= Raw'Last loop
            if Index + Splice'Length - 1 <= Raw'Last
              and then Raw (Index .. Index + Splice'Length - 1) = Splice
            then
               --  Skip the splice but keep any pending space: it belongs to
               --  the literal ("... rejection " & "from ...") and dropping it
               --  would fuse the two words together.
               Index := Index + Splice'Length;
            elsif Is_Space (Raw (Index)) then
               Space := True;
               Index := Index + 1;
            else
               if Space and then Last > 0 then
                  Last := Last + 1;
                  Result (Last) := ' ';
               end if;
               Space := False;
               Last := Last + 1;
               Result (Last) := Raw (Index);
               Index := Index + 1;
            end if;
         end loop;
         return Result (1 .. Last);
      end;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Load_Normalized;

   --  Load a file as a single string with newlines rendered as spaces. The
   --  registry writes JSON arrays inline, so scanning must not be line-based.
   function Load_Flat (Path : String; Found : out Boolean) return String is
      File   : Ada.Text_IO.File_Type;
      Buffer : Unbounded_String;
   begin
      Found := Ada.Directories.Exists (Path);
      if not Found then
         return "";
      end if;

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
   end Load_Flat;

   --  Count non-overlapping occurrences of Pattern in Text.
   function Occurrences (Text : String; Pattern : String) return Natural is
      Count : Natural := 0;
      Index : Natural := Text'First;
      Hit   : Natural;
   begin
      loop
         Hit := Ada.Strings.Fixed.Index (Text (Index .. Text'Last), Pattern);
         exit when Hit = 0;
         Count := Count + 1;
         Index := Hit + Pattern'Length;
         exit when Index > Text'Last;
      end loop;
      return Count;
   end Occurrences;

   procedure Validate (Report : out Validation_Report) is
      Have_Test_Source : Boolean;
      Have_Gate_Tests  : Boolean;
      Have_Conformance : Boolean;
      Have_Examples    : Boolean;
      Have_Registry    : Boolean;
      Marker           : constant String := """required_tests"": [";
   begin
      Report := (others => 0);

      declare
         Registry : constant String := Load_Flat (Registry_Path, Have_Registry);
         Suite    : constant String :=
           Load_Normalized (Evidence_Path (Test_Suite), Have_Test_Source);
         Gates    : constant String :=
           Load_Normalized (Evidence_Path (Gate_Self_Tests), Have_Gate_Tests);
         Certify  : constant String :=
           Load_Normalized (Evidence_Path (Conformance), Have_Conformance);
         Sample   : constant String :=
           Load_Normalized (Evidence_Path (Examples), Have_Examples);
         Index    : Natural;
         Hit      : Natural;

         --  A name is traced when any evidence source states it verbatim.
         function Traced (Name : String) return Boolean is
           ((Have_Test_Source and then Ada.Strings.Fixed.Index (Suite, Name) /= 0)
            or else (Have_Gate_Tests
                     and then Ada.Strings.Fixed.Index (Gates, Name) /= 0)
            or else (Have_Conformance
                     and then Ada.Strings.Fixed.Index (Certify, Name) /= 0)
            or else (Have_Examples
                     and then Ada.Strings.Fixed.Index (Sample, Name) /= 0));
      begin
         if not Have_Registry then
            Ada.Text_IO.Put_Line ("invariants:missing-registry:" & Registry_Path);
            return;
         end if;

         --  Every evidence source must exist; a deleted one would otherwise
         --  silently turn its invariants into untraced findings, or worse,
         --  look like a clean run if nothing referenced it.
         for Source in Evidence_Source loop
            if not Ada.Directories.Exists (Evidence_Path (Source)) then
               Report.Missing_Test_Source := Report.Missing_Test_Source + 1;
               Ada.Text_IO.Put_Line
                 ("invariants:missing-evidence-source:" & Evidence_Path (Source));
            end if;
         end loop;

         Report.Invariant_Count :=
           Occurrences (Registry, """id"": ""IDENTITY-");

         --  Collect every id and flag any that appears twice.
         declare
            Max_Ids : constant := 512;
            type Id_Array is array (1 .. Max_Ids) of Unbounded_String;
            Ids     : Id_Array := [others => Null_Unbounded_String];
            Count   : Natural := 0;
            Marker  : constant String := """id"": """;
            Cursor  : Natural := Registry'First;
         begin
            loop
               declare
                  Hit : constant Natural :=
                    Ada.Strings.Fixed.Index (Registry (Cursor .. Registry'Last), Marker);
                  Stop : Natural;
               begin
                  exit when Hit = 0;
                  Stop := Hit + Marker'Length;
                  while Stop <= Registry'Last and then Registry (Stop) /= '"' loop
                     Stop := Stop + 1;
                  end loop;
                  exit when Stop > Registry'Last;

                  declare
                     Id : constant String :=
                       Registry (Hit + Marker'Length .. Stop - 1);
                  begin
                     for Index in 1 .. Count loop
                        if To_String (Ids (Index)) = Id then
                           Report.Duplicate_Ids := Report.Duplicate_Ids + 1;
                           Ada.Text_IO.Put_Line
                             ("invariants:duplicate-id:" & Id);
                        end if;
                     end loop;
                     if Count < Max_Ids then
                        Count := Count + 1;
                        Ids (Count) := To_Unbounded_String (Id);
                     end if;
                  end;
                  Cursor := Stop + 1;
                  exit when Cursor > Registry'Last;
               end;
            end loop;
         end;
         Report.Failure_Severity_Count :=
           Occurrences (Registry, """failure_severity"":");

         --  Walk each required_tests array and check every listed name really
         --  appears as an assertion message in the suite.
         Index := Registry'First;
         loop
            Hit := Ada.Strings.Fixed.Index (Registry (Index .. Registry'Last), Marker);
            exit when Hit = 0;
            Report.Required_Test_Block_Count := Report.Required_Test_Block_Count + 1;

            declare
               Cursor  : Natural := Hit + Marker'Length;
               Entries : Natural := 0;
               First   : Natural;
            begin
               loop
                  exit when Cursor > Registry'Last;
                  exit when Registry (Cursor) = ']';
                  if Registry (Cursor) = '"' then
                     First := Cursor + 1;
                     Cursor := First;
                     while Cursor <= Registry'Last
                       and then Registry (Cursor) /= '"'
                     loop
                        Cursor := Cursor + 1;
                     end loop;
                     exit when Cursor > Registry'Last;

                     declare
                        Name : constant String := Registry (First .. Cursor - 1);
                     begin
                        if Name'Length > 0 then
                           Entries := Entries + 1;
                           Report.Required_Test_Names :=
                             Report.Required_Test_Names + 1;
                           if Traced (Name) then
                              Report.Traced_Required_Tests :=
                                Report.Traced_Required_Tests + 1;
                           else
                              Report.Untraced_Required_Tests :=
                                Report.Untraced_Required_Tests + 1;
                              Ada.Text_IO.Put_Line
                                ("invariants:untraced-required-test:" & Name);
                           end if;
                        end if;
                     end;
                  end if;
                  Cursor := Cursor + 1;
               end loop;

               if Entries = 0 then
                  Report.Empty_Required_Test_Blocks :=
                    Report.Empty_Required_Test_Blocks + 1;
               end if;
               Index := Cursor;
            end;
            exit when Index > Registry'Last;
         end loop;
      end;
   end Validate;

   function Passed (Report : Validation_Report) return Boolean is
     (Report.Invariant_Count > 0
      and then Report.Required_Test_Block_Count = Report.Invariant_Count
      and then Report.Failure_Severity_Count = Report.Invariant_Count
      and then Report.Empty_Required_Test_Blocks = 0
      and then Report.Missing_Test_Source = 0
      and then Report.Required_Test_Names > 0
      and then Report.Untraced_Required_Tests = 0
      and then Report.Duplicate_Ids = 0);

end Identity_Tools_Invariants;
