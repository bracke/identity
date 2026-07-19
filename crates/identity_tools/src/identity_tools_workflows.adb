with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Text_IO;

package body Identity_Tools_Workflows is

   type Workflow_Id is
     (Check,
      Test,
      Security_Check,
      Conformance,
      Proof,
      Documentation_Check,
      Fixtures_Check,
      Release_Check,
      Release_Artifacts);

   type Gate_Id is
     (Alire_Build,
      Architecture_Scan,
      Identity_Tools_Architecture,
      Identity_Tools_Workflows,
      Invariant_Registry_Parse,
      Identity_Tools_Invariants,
      AUnit,
      Examples_Build,
      Fixture_Determinism,
      Secret_Leak_Canary_Scan,
      Identity_Tools_Secret_Leaks,
      Cryptolib_Import_Isolation,
      Authorization_Boundary_Scan,
      Crypto_Algorithm_Registry,
      Identity_Tools_Crypto_Validation,
      Repository_Conformance,
      Conformance_Crate_Build,
      Memory_Reference_Adapter,
      GNATprove,
      AI_Docs,
      Public_Contract_Docs,
      Threat_Model,
      Persisted_Format_Registry,
      Persisted_Format_Compatibility,
      Identity_Tools_Persisted_Validation,
      Release_Build,
      Tools_Crate_Build,
      Cryptolib_Self_Tests,
      Fault_Injection,
      Concurrency,
      Disclosure,
      Resource_Bounds,
      Event_Coverage,
      Identity_Tools_Events,
      Documentation_Check_Gate,
      Archive_Hygiene,
      Artifact_Verification,
      Release_Artifact_Inventory,
      Identity_Tools_Release_Validation,
      Provenance,
      Digests,
      Reports,
      Prohibited_Material_Scan);

   type Workflow_Presence is array (Workflow_Id) of Boolean;
   type Gate_Presence is array (Gate_Id) of Boolean;

   Expected_Workflow_Count : constant Natural :=
     Workflow_Id'Pos (Workflow_Id'Last) + 1;
   Expected_Gate_Count : constant Natural := Gate_Id'Pos (Gate_Id'Last) + 1;

   function Contains (Line : String; Pattern : String) return Boolean is
     (Ada.Strings.Fixed.Index (Line, Pattern) /= 0);

   function Manifest_Path return String is
     (if Ada.Directories.Exists ("tools/project_tools_workflows.toml") then
        "tools/project_tools_workflows.toml"
      else
        "../../tools/project_tools_workflows.toml");

   function Image (Id : Workflow_Id) return String is
     (case Id is
        when Check => "check",
        when Test => "test",
        when Security_Check => "security-check",
        when Conformance => "conformance",
        when Proof => "proof",
        when Documentation_Check => "documentation-check",
        when Fixtures_Check => "fixtures-check",
        when Release_Check => "release-check",
        when Release_Artifacts => "release-artifacts");

   function Image (Id : Gate_Id) return String is
     (case Id is
        when Alire_Build => "alire-build",
        when Architecture_Scan => "architecture-scan",
        when Identity_Tools_Architecture => "identity-tools-architecture",
        when Identity_Tools_Workflows => "identity-tools-workflows",
        when Invariant_Registry_Parse => "invariant-registry-parse",
        when Identity_Tools_Invariants => "identity-tools-invariants",
        when AUnit => "aunit",
        when Examples_Build => "examples-build",
        when Fixture_Determinism => "fixture-determinism",
        when Secret_Leak_Canary_Scan => "secret-leak-canary-scan",
        when Identity_Tools_Secret_Leaks => "identity-tools-secret-leaks",
        when Cryptolib_Import_Isolation => "cryptolib-import-isolation",
        when Authorization_Boundary_Scan => "authorization-boundary-scan",
        when Crypto_Algorithm_Registry => "crypto-algorithm-registry",
        when Identity_Tools_Crypto_Validation =>
          "identity-tools-crypto-validation",
        when Repository_Conformance => "repository-conformance",
        when Conformance_Crate_Build => "conformance-crate-build",
        when Memory_Reference_Adapter => "memory-reference-adapter",
        when GNATprove => "gnatprove",
        when AI_Docs => "ai-docs",
        when Public_Contract_Docs => "public-contract-docs",
        when Threat_Model => "threat-model",
        when Persisted_Format_Registry => "persisted-format-registry",
        when Persisted_Format_Compatibility =>
          "persisted-format-compatibility",
        when Identity_Tools_Persisted_Validation =>
          "identity-tools-persisted-validation",
        when Release_Build => "release-build",
        when Tools_Crate_Build => "tools-crate-build",
        when Cryptolib_Self_Tests => "cryptolib-self-tests",
        when Fault_Injection => "fault-injection",
        when Concurrency => "concurrency",
        when Disclosure => "disclosure",
        when Resource_Bounds => "resource-bounds",
        when Event_Coverage => "event-coverage",
        when Identity_Tools_Events => "identity-tools-events",
        when Documentation_Check_Gate => "documentation-check",
        when Archive_Hygiene => "archive-hygiene",
        when Artifact_Verification => "artifact-verification",
        when Release_Artifact_Inventory => "release-artifact-inventory",
        when Identity_Tools_Release_Validation =>
          "identity-tools-release-validation",
        when Provenance => "provenance",
        when Digests => "digests",
        when Reports => "reports",
        when Prohibited_Material_Scan => "prohibited-material-scan");

   procedure Validate (Report : out Validation_Report) is
      File      : Ada.Text_IO.File_Type;
      Workflows : Workflow_Presence := [others => False];
      Gates     : Gate_Presence := [others => False];
   begin
      Report := (others => 0);
      Report.Missing_Orchestrator := 1;

      if not Ada.Directories.Exists (Manifest_Path) then
         Ada.Text_IO.Put_Line ("workflows:missing-manifest:" & Manifest_Path);
         return;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Manifest_Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (File);
         begin
            if Contains (Line, "required = ""project_tools""") then
               Report.Missing_Orchestrator := 0;
            end if;

            if Contains (Line, "name = ""identity""")
              or else Contains (Line, "crate = ""identity""")
              or else Contains (Line, "root_package = ""Identity""")
              or else Contains (Line, "gpr = ""identity.gpr""")
            then
               Report.Missing_Project_Metadata :=
                 Report.Missing_Project_Metadata + 1;
            end if;

            for Id in Workflow_Id loop
               if Contains (Line, "name = """ & Image (Id) & """") then
                  if not Workflows (Id) then
                     Report.Workflow_Count := Report.Workflow_Count + 1;
                  end if;
                  Workflows (Id) := True;
               end if;
            end loop;

            for Id in Gate_Id loop
               if Contains (Line, """" & Image (Id) & """") then
                  if not Gates (Id) then
                     Report.Gate_Count := Report.Gate_Count + 1;
                  end if;
                  Gates (Id) := True;
               end if;
            end loop;
         end;
      end loop;
      Ada.Text_IO.Close (File);

      if Report.Missing_Project_Metadata = 4 then
         Report.Missing_Project_Metadata := 0;
      else
         Report.Missing_Project_Metadata := 4 - Report.Missing_Project_Metadata;
      end if;

      for Id in Workflow_Id loop
         if not Workflows (Id) then
            Report.Missing_Workflows := Report.Missing_Workflows + 1;
            Ada.Text_IO.Put_Line ("workflows:missing-workflow:" & Image (Id));
         end if;
      end loop;

      for Id in Gate_Id loop
         if not Gates (Id) then
            Report.Missing_Gates := Report.Missing_Gates + 1;
            Ada.Text_IO.Put_Line ("workflows:missing-gate:" & Image (Id));
         end if;
      end loop;

      if Report.Missing_Orchestrator /= 0 then
         Ada.Text_IO.Put_Line ("workflows:missing-orchestrator:project_tools");
      end if;

      if Report.Missing_Project_Metadata /= 0 then
         Ada.Text_IO.Put_Line ("workflows:missing-project-metadata");
      end if;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Validate;

   function Passed (Report : Validation_Report) return Boolean is
     (Report.Workflow_Count = Expected_Workflow_Count
      and then Report.Gate_Count = Expected_Gate_Count
      and then Report.Missing_Workflows = 0
      and then Report.Missing_Gates = 0
      and then Report.Missing_Orchestrator = 0
      and then Report.Missing_Project_Metadata = 0);

end Identity_Tools_Workflows;
