with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Text_IO;

package body Identity_Tools_Release_Validation is

   type Artifact_Id is
     (Source_Archive,
      Alire_Metadata,
      API_Documentation,
      Package_Map,
      Threat_Model,
      Invariant_Traceability,
      Adapter_Conformance,
      Crypto_Capability_Inventory,
      Persisted_Format_Compatibility,
      Test_Summary,
      Proof_Summary,
      Changelog,
      Migration_Notes,
      Artifact_Digests,
      Release_Provenance);

   type Prohibited_Id is
     (Private_Keys,
      Environment_Files,
      Temporary_Secrets,
      Local_Databases,
      Sensitive_Logs,
      Unreleased_Vulnerability_Notes,
      Test_Entropy_State,
      Raw_Verifier_Payload_Reports);

   type Provenance_Field_Id is
     (Source_Commit,
      Crate_Version,
      Alire_Lockfile_Digest,
      Compiler_Version,
      Cryptolib_Version,
      Project_Tools_Version,
      Proof_Configuration,
      Build_Profile,
      Enabled_Capabilities);

   type Artifact_Presence is array (Artifact_Id) of Boolean;
   type Prohibited_Presence is array (Prohibited_Id) of Boolean;
   type Provenance_Presence is array (Provenance_Field_Id) of Boolean;

   Expected_Artifact_Count : constant Natural :=
     Artifact_Id'Pos (Artifact_Id'Last) + 1;
   Expected_Prohibited_Count : constant Natural :=
     Prohibited_Id'Pos (Prohibited_Id'Last) + 1;
   Expected_Provenance_Count : constant Natural :=
     Provenance_Field_Id'Pos (Provenance_Field_Id'Last) + 1;

   function Contains (Line : String; Pattern : String) return Boolean is
     (Ada.Strings.Fixed.Index (Line, Pattern) /= 0);

   function Registry_Path return String is
     (if Ada.Directories.Exists ("registries/release-artifacts.json") then
        "registries/release-artifacts.json"
      else
        "../../registries/release-artifacts.json");

   function Image (Id : Artifact_Id) return String is
     (case Id is
        when Source_Archive => "identity.source-archive",
        when Alire_Metadata => "identity.alire-metadata",
        when API_Documentation => "identity.api-documentation",
        when Package_Map => "identity.package-map",
        when Threat_Model => "identity.threat-model",
        when Invariant_Traceability => "identity.invariant-traceability",
        when Adapter_Conformance => "identity.adapter-conformance",
        when Crypto_Capability_Inventory => "identity.crypto-capability-inventory",
        when Persisted_Format_Compatibility => "identity.persisted-format-compatibility",
        when Test_Summary => "identity.test-summary",
        when Proof_Summary => "identity.proof-summary",
        when Changelog => "identity.changelog",
        when Migration_Notes => "identity.migration-notes",
        when Artifact_Digests => "identity.artifact-digests",
        when Release_Provenance => "identity.release-provenance");

   function Image (Id : Prohibited_Id) return String is
     (case Id is
        when Private_Keys => "private-keys",
        when Environment_Files => "environment-files",
        when Temporary_Secrets => "temporary-secrets",
        when Local_Databases => "local-databases",
        when Sensitive_Logs => "sensitive-logs",
        when Unreleased_Vulnerability_Notes => "unreleased-vulnerability-notes",
        when Test_Entropy_State => "test-entropy-state",
        when Raw_Verifier_Payload_Reports => "raw-verifier-payload-reports");

   function Image (Id : Provenance_Field_Id) return String is
     (case Id is
        when Source_Commit => "source-commit",
        when Crate_Version => "crate-version",
        when Alire_Lockfile_Digest => "alire-lockfile-digest",
        when Compiler_Version => "compiler-version",
        when Cryptolib_Version => "cryptolib-version",
        when Project_Tools_Version => "project-tools-version",
        when Proof_Configuration => "proof-configuration",
        when Build_Profile => "build-profile",
        when Enabled_Capabilities => "enabled-capabilities");

   procedure Validate (Report : out Validation_Report) is
      File       : Ada.Text_IO.File_Type;
      Artifacts  : Artifact_Presence := [others => False];
      Prohibited : Prohibited_Presence := [others => False];
      Provenance : Provenance_Presence := [others => False];
   begin
      Report := (others => 0);

      if not Ada.Directories.Exists (Registry_Path) then
         Ada.Text_IO.Put_Line ("release-artifacts:missing-registry:" & Registry_Path);
         return;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Registry_Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (File);
         begin
            for Id in Artifact_Id loop
               if Contains (Line, """" & Image (Id) & """") then
                  if not Artifacts (Id) then
                     Report.Artifact_Count := Report.Artifact_Count + 1;
                  end if;
                  Artifacts (Id) := True;
               end if;
            end loop;

            for Id in Prohibited_Id loop
               if Contains (Line, """" & Image (Id) & """") then
                  if not Prohibited (Id) then
                     Report.Prohibited_Count := Report.Prohibited_Count + 1;
                  end if;
                  Prohibited (Id) := True;
               end if;
            end loop;

            for Id in Provenance_Field_Id loop
               if Contains (Line, """" & Image (Id) & """") then
                  if not Provenance (Id) then
                     Report.Provenance_Field_Count := Report.Provenance_Field_Count + 1;
                  end if;
                  Provenance (Id) := True;
               end if;
            end loop;

            if Contains (Line, """required"": true") then
               Report.Required_Count := Report.Required_Count + 1;
            end if;

            if Contains (Line, """contains_sensitive_material"": true") then
               Report.Sensitive_Count := Report.Sensitive_Count + 1;
            end if;
         end;
      end loop;
      Ada.Text_IO.Close (File);

      for Id in Artifact_Id loop
         if not Artifacts (Id) then
            Report.Missing_Artifacts := Report.Missing_Artifacts + 1;
            Ada.Text_IO.Put_Line ("release-artifacts:missing-artifact:" & Image (Id));
         end if;
      end loop;

      for Id in Prohibited_Id loop
         if not Prohibited (Id) then
            Report.Missing_Prohibited := Report.Missing_Prohibited + 1;
            Ada.Text_IO.Put_Line ("release-artifacts:missing-prohibited:" & Image (Id));
         end if;
      end loop;

      for Id in Provenance_Field_Id loop
         if not Provenance (Id) then
            Report.Missing_Provenance := Report.Missing_Provenance + 1;
            Ada.Text_IO.Put_Line ("release-artifacts:missing-provenance:" & Image (Id));
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
     (Report.Artifact_Count = Expected_Artifact_Count
      and then Report.Required_Count = Expected_Artifact_Count
      and then Report.Sensitive_Count = 0
      and then Report.Prohibited_Count = Expected_Prohibited_Count
      and then Report.Provenance_Field_Count = Expected_Provenance_Count
      and then Report.Missing_Artifacts = 0
      and then Report.Missing_Prohibited = 0
      and then Report.Missing_Provenance = 0);

end Identity_Tools_Release_Validation;
