with Ada.Directories;
with Ada.Text_IO;

with Identity.Version;
with Identity_Tools_Evidence;
with Identity_Tools_Persisted_Formats;
with Identity_Tools_Release_Artifacts;

package body Identity_Tools_Release_Reports is

   type Output_Id is
     (Artifact_Inventory,
      Test_Summary,
      Proof_Summary,
      Crypto_Inventory,
      Traceability_Report,
      Release_Provenance,
      Artifact_Digests,
      Package_Map,
      Threat_Model,
      Adapter_Conformance,
      Changelog_Report,
      Migration_Notes,
      Persisted_Format_Compat);

   Expected_Output_Count : constant Natural := Output_Id'Pos (Output_Id'Last) + 1;

   function Prefix return String is
     (if Ada.Directories.Exists ("registries/release-artifacts.json") then
        ""
      else
        "../../");

   function Output_Dir return String is
     (Prefix & "generated/release");

   function Path (Id : Output_Id) return String is
     (case Id is
        when Artifact_Inventory =>
          Output_Dir & "/artifact-inventory.txt",
        when Test_Summary =>
          Output_Dir & "/test-summary.txt",
        when Proof_Summary =>
          Output_Dir & "/proof-summary.txt",
        when Crypto_Inventory =>
          Output_Dir & "/crypto-capability-inventory.txt",
        when Traceability_Report =>
          Output_Dir & "/invariant-traceability-report.txt",
        when Release_Provenance =>
          Output_Dir & "/release-provenance.txt",
        when Artifact_Digests =>
          Output_Dir & "/artifact-digests.txt",
        when Package_Map =>
          Output_Dir & "/package-map.txt",
        when Threat_Model =>
          Output_Dir & "/threat-model.txt",
        when Adapter_Conformance =>
          Output_Dir & "/adapter-conformance-report.txt",
        when Changelog_Report =>
          Output_Dir & "/changelog.txt",
        when Migration_Notes =>
          Output_Dir & "/migration-notes.txt",
        when Persisted_Format_Compat =>
          Output_Dir & "/persisted-format-compatibility.txt");

   procedure Write_Output (Id : Output_Id; Report : in out Generation_Report) is
      File : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Path (Id));
      case Id is
         when Artifact_Inventory =>
            --  Two distinct counts, not one: how many artifacts the release
            --  requires (from the registry) versus how many identity_tools
            --  generates here. Reporting only the former read as if all were
            --  produced; the remaining required artifacts are repository
            --  documents collected outside this generator.
            Ada.Text_IO.Put_Line (File, "required-artifact-count:"
              & Natural'Image (Identity_Tools_Release_Artifacts.Required_Artifact_Count));
            Ada.Text_IO.Put_Line (File, "generated-report-count:"
              & Natural'Image (Expected_Output_Count));
            Ada.Text_IO.Put_Line (File, "prohibited-material-count:"
              & Natural'Image (Identity_Tools_Release_Artifacts.Prohibited_Material_Count));
            Ada.Text_IO.Put_Line (File, "provenance-field-count:"
              & Natural'Image (Identity_Tools_Release_Artifacts.Provenance_Field_Count));
            Ada.Text_IO.Put_Line (File, "sensitive-artifacts: 0");
         when Test_Summary =>
            --  Outcomes of the runs that actually happened, not a list of
            --  suites that were supposed to happen.
            Ada.Text_IO.Put_Line (File, "suite:aunit:"
              & Identity_Tools_Evidence.State_Image
                  (Identity_Tools_Evidence.State (Identity_Tools_Evidence.AUnit_Suite))
              & ":" & Identity_Tools_Evidence.Detail (Identity_Tools_Evidence.AUnit_Suite));
            Ada.Text_IO.Put_Line (File, "suite:repository-conformance:"
              & Identity_Tools_Evidence.State_Image
                  (Identity_Tools_Evidence.State (Identity_Tools_Evidence.Conformance))
              & ":" & Identity_Tools_Evidence.Detail (Identity_Tools_Evidence.Conformance));
            Ada.Text_IO.Put_Line (File, "suite:gate-selftests:"
              & Identity_Tools_Evidence.State_Image
                  (Identity_Tools_Evidence.State (Identity_Tools_Evidence.Gate_Self_Tests))
              & ":" & Identity_Tools_Evidence.Detail (Identity_Tools_Evidence.Gate_Self_Tests));
            Ada.Text_IO.Put_Line (File, "suite:examples:"
              & Identity_Tools_Evidence.State_Image
                  (Identity_Tools_Evidence.State (Identity_Tools_Evidence.Examples))
              & ":" & Identity_Tools_Evidence.Detail (Identity_Tools_Evidence.Examples));
         when Proof_Summary =>
            Ada.Text_IO.Put_Line (File, "gate:gnatprove:"
              & Identity_Tools_Evidence.State_Image
                  (Identity_Tools_Evidence.State (Identity_Tools_Evidence.Proof))
              & ":" & Identity_Tools_Evidence.Detail (Identity_Tools_Evidence.Proof));
            Ada.Text_IO.Put_Line (File, "orchestrator:project_tools");
            Ada.Text_IO.Put_Line (File, "baseline-rule:no-silent-lowering");
         when Crypto_Inventory =>
            Ada.Text_IO.Put_Line (File, "provider:cryptolib");
            Ada.Text_IO.Put_Line (File, "password-hashing:registered");
            Ada.Text_IO.Put_Line (File, "secret-verifiers:registered");
            Ada.Text_IO.Put_Line (File, "constant-time:registered");
            Ada.Text_IO.Put_Line (File, "event-integrity:registered");
         when Traceability_Report =>
            Ada.Text_IO.Put_Line (File, "invariant-registry:registries/invariants.json");
            Ada.Text_IO.Put_Line (File, "required-test-metadata:required");
            Ada.Text_IO.Put_Line (File, "failure-severity:required");
         when Release_Provenance =>
            Ada.Text_IO.Put_Line (File, "crate-name:" & Identity.Version.Crate_Name);
            Ada.Text_IO.Put_Line (File, "crate-version:"
              & Natural'Image (Identity.Version.V1_Major) & "."
              & Natural'Image (Identity.Version.V1_Minor) & "."
              & Natural'Image (Identity.Version.V1_Patch));
            Ada.Text_IO.Put_Line (File, "crate-status:" & Identity.Version.Status);
            Ada.Text_IO.Put_Line (File, "build-profile:release-required");
            Ada.Text_IO.Put_Line (File, "enabled-capabilities:identity-core");
         when Artifact_Digests =>
            Ada.Text_IO.Put_Line (File, "digest-records:declared");
            Ada.Text_IO.Put_Line (File, "persisted-format-count:"
              & Natural'Image (Identity_Tools_Persisted_Formats.Format_Count));
            Ada.Text_IO.Put_Line (File, "fixture-count:"
              & Natural'Image (Identity_Tools_Persisted_Formats.Fixture_Count));
         when Package_Map =>
            Ada.Text_IO.Put_Line (File, "source:docs/ai/package-map.md");
            Ada.Text_IO.Put_Line (File, "public-spec-root:src/public");
            Ada.Text_IO.Put_Line (File, "adapter-spec-root:src/adapters");
         when Threat_Model =>
            Ada.Text_IO.Put_Line (File, "source:docs/threat-model.md");
            Ada.Text_IO.Put_Line (File, "invariant-registry:registries/invariants.json");
         when Adapter_Conformance =>
            Ada.Text_IO.Put_Line (File, "gate:conformance:"
              & Identity_Tools_Evidence.State_Image
                  (Identity_Tools_Evidence.State
                     (Identity_Tools_Evidence.Conformance))
              & ":" & Identity_Tools_Evidence.Detail
                        (Identity_Tools_Evidence.Conformance));
            Ada.Text_IO.Put_Line (File, "profiles:core,interactive,session,recovery,federated");
         when Changelog_Report =>
            Ada.Text_IO.Put_Line (File, "source:CHANGELOG.md");
            Ada.Text_IO.Put_Line (File, "crate-version:"
              & Natural'Image (Identity.Version.V1_Major) & "."
              & Natural'Image (Identity.Version.V1_Minor) & "."
              & Natural'Image (Identity.Version.V1_Patch));
         when Migration_Notes =>
            Ada.Text_IO.Put_Line (File, "source:docs/migrations");
            Ada.Text_IO.Put_Line (File, "persisted-format-versions:"
              & Natural'Image (Identity_Tools_Persisted_Formats.Format_Count));
         when Persisted_Format_Compat =>
            Ada.Text_IO.Put_Line (File, "format-count:"
              & Natural'Image (Identity_Tools_Persisted_Formats.Format_Count));
            Ada.Text_IO.Put_Line (File, "fixture-count:"
              & Natural'Image (Identity_Tools_Persisted_Formats.Fixture_Count));
            Ada.Text_IO.Put_Line (File, "source-registry:registries/persisted-formats.json");
      end case;
      Ada.Text_IO.Close (File);
      Report.Output_Count := Report.Output_Count + 1;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         Report.Write_Failures := Report.Write_Failures + 1;
   end Write_Output;

   procedure Generate (Report : out Generation_Report) is
   begin
      Report := (others => 0);
      Ada.Directories.Create_Path (Output_Dir);

      for Id in Output_Id loop
         Write_Output (Id, Report);
      end loop;
   exception
      when others =>
         Report.Write_Failures := Report.Write_Failures + 1;
   end Generate;

   function Passed (Report : Generation_Report) return Boolean is
     (Report.Output_Count = Expected_Output_Count
      and then Report.Write_Failures = 0
      and then Report.Skipped = 0);

end Identity_Tools_Release_Reports;
