with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Text_IO;

package body Identity_Tools_Persisted_Validation is

   type Format_Id is
     (Canonical_Frame,
      Secret_Verifier_Text,
      Event_Canonical_Envelope);

   type Fixture_Id is
     (Canonical_Frame_Current,
      Canonical_Frame_Historical_V1,
      Canonical_Frame_Malformed,
      Canonical_Frame_Maximum_Size,
      Canonical_Frame_Future_Version,
      Canonical_Frame_Noncanonical,
      Secret_Verifier_Current,
      Secret_Verifier_Malformed,
      Secret_Verifier_Future_Version,
      Event_Envelope_Current,
      Event_Envelope_Maximum_Size,
      Event_Envelope_Noncanonical);

   type Requirement_Id is
     (Deterministic,
      Byte_Order_Network,
      Framed,
      Length_Delimited,
      Bounded,
      Future_Versions_Rejected,
      Malformed_Forms_Rejected,
      Noncanonical_Forms_Rejected);

   type Format_Presence is array (Format_Id) of Boolean;
   type Fixture_Presence is array (Fixture_Id) of Boolean;
   type Requirement_Presence is array (Requirement_Id) of Boolean;

   Expected_Format_Count : constant Natural := Format_Id'Pos (Format_Id'Last) + 1;
   Expected_Fixture_Count : constant Natural := Fixture_Id'Pos (Fixture_Id'Last) + 1;
   Expected_Requirement_Count : constant Natural :=
     Requirement_Id'Pos (Requirement_Id'Last) + 1;

   function Contains (Line : String; Pattern : String) return Boolean is
     (Ada.Strings.Fixed.Index (Line, Pattern) /= 0);

   function Prefix return String is
     (if Ada.Directories.Exists ("registries/persisted-formats.json") then
        ""
      else
        "../../");

   function Registry_Path return String is
     (Prefix & "registries/persisted-formats.json");

   function Image (Id : Format_Id) return String is
     (case Id is
        when Canonical_Frame => "identity.codec.canonical-frame",
        when Secret_Verifier_Text => "identity.crypto.secret-verifier-text",
        when Event_Canonical_Envelope => "identity.event.canonical-envelope");

   function Image (Id : Fixture_Id) return String is
     (case Id is
        when Canonical_Frame_Current =>
          "fixtures/persisted-formats/canonical-frame-current.json",
        when Canonical_Frame_Historical_V1 =>
          "fixtures/persisted-formats/canonical-frame-historical-v1.json",
        when Canonical_Frame_Malformed =>
          "fixtures/persisted-formats/canonical-frame-malformed.json",
        when Canonical_Frame_Maximum_Size =>
          "fixtures/persisted-formats/canonical-frame-maximum-size.json",
        when Canonical_Frame_Future_Version =>
          "fixtures/persisted-formats/canonical-frame-future-version.json",
        when Canonical_Frame_Noncanonical =>
          "fixtures/persisted-formats/canonical-frame-noncanonical.json",
        when Secret_Verifier_Current =>
          "fixtures/persisted-formats/secret-verifier-current.json",
        when Secret_Verifier_Malformed =>
          "fixtures/persisted-formats/secret-verifier-malformed.json",
        when Secret_Verifier_Future_Version =>
          "fixtures/persisted-formats/secret-verifier-future-version.json",
        when Event_Envelope_Current =>
          "fixtures/persisted-formats/event-envelope-current.json",
        when Event_Envelope_Maximum_Size =>
          "fixtures/persisted-formats/event-envelope-maximum-size.json",
        when Event_Envelope_Noncanonical =>
          "fixtures/persisted-formats/event-envelope-noncanonical.json");

   function Image (Id : Requirement_Id) return String is
     (case Id is
        when Deterministic => """deterministic"": true",
        when Byte_Order_Network => """byte_order"": ""network""",
        when Framed => """framed"": true",
        when Length_Delimited => """length_delimited"": true",
        when Bounded => """bounded"": true",
        when Future_Versions_Rejected => """future_versions_rejected"": true",
        when Malformed_Forms_Rejected => """malformed_forms_rejected"": true",
        when Noncanonical_Forms_Rejected => """noncanonical_forms_rejected"": true");

   procedure Validate (Report : out Validation_Report) is
      File         : Ada.Text_IO.File_Type;
      Formats      : Format_Presence := [others => False];
      Fixtures     : Fixture_Presence := [others => False];
      Requirements : Requirement_Presence := [others => False];
   begin
      Report := (others => 0);

      if not Ada.Directories.Exists (Registry_Path) then
         Ada.Text_IO.Put_Line ("persisted-formats:missing-registry:" & Registry_Path);
         return;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Registry_Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (File);
         begin
            for Id in Format_Id loop
               if Contains (Line, """" & Image (Id) & """") then
                  if not Formats (Id) then
                     Report.Format_Count := Report.Format_Count + 1;
                  end if;
                  Formats (Id) := True;
               end if;
            end loop;

            for Id in Fixture_Id loop
               if Contains (Line, """" & Image (Id) & """") then
                  if not Fixtures (Id) then
                     Report.Fixture_Count := Report.Fixture_Count + 1;
                  end if;
                  Fixtures (Id) := True;
               end if;
            end loop;

            for Id in Requirement_Id loop
               if Contains (Line, Image (Id)) then
                  if not Requirements (Id) then
                     Report.Requirement_Count := Report.Requirement_Count + 1;
                  end if;
                  Requirements (Id) := True;
               end if;
            end loop;
         end;
      end loop;
      Ada.Text_IO.Close (File);

      for Id in Format_Id loop
         if not Formats (Id) then
            Report.Missing_Formats := Report.Missing_Formats + 1;
            Ada.Text_IO.Put_Line ("persisted-formats:missing-format:" & Image (Id));
         end if;
      end loop;

      for Id in Fixture_Id loop
         if not Fixtures (Id) then
            Report.Missing_Fixtures := Report.Missing_Fixtures + 1;
            Ada.Text_IO.Put_Line ("persisted-formats:missing-fixture:" & Image (Id));
         elsif not Ada.Directories.Exists (Prefix & Image (Id)) then
            Report.Missing_Fixture_Files := Report.Missing_Fixture_Files + 1;
            Ada.Text_IO.Put_Line ("persisted-formats:missing-fixture-file:" & Image (Id));
         end if;
      end loop;

      for Id in Requirement_Id loop
         if not Requirements (Id) then
            Report.Missing_Requirements := Report.Missing_Requirements + 1;
            Ada.Text_IO.Put_Line ("persisted-formats:missing-requirement:" & Image (Id));
         end if;
      end loop;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Validate;

   function Passed (Report : Validation_Report) return Boolean is
     (Report.Format_Count = Expected_Format_Count
      and then Report.Fixture_Count = Expected_Fixture_Count
      and then Report.Missing_Formats = 0
      and then Report.Missing_Fixtures = 0
      and then Report.Missing_Requirements = 0
      and then Report.Requirement_Count = Expected_Requirement_Count
      and then Report.Missing_Fixture_Files = 0);

end Identity_Tools_Persisted_Validation;
