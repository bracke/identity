with Ada.Text_IO;
with Ada.Command_Line;
with Identity_Tools_Architecture;
with Identity_Tools_Audit_Coverage;
with Identity_Tools_Capabilities;
with Identity_Tools_Crypto_Validation;
with Identity_Tools_Documentation;
with Identity_Tools_Events;
with Identity_Tools_Gap_Claims;
with Identity_Tools_Evidence;
with Identity_Tools_Invariants;
with Identity_Tools_Secret_Leaks;
with Identity.Version;
with Identity_Tools_Persisted_Formats;
with Identity_Tools_Persisted_Validation;
with Identity_Tools_Proof_Validation;
with Identity_Tools_Release_Artifacts;
with Identity_Tools_Release_Reports;
with Identity_Tools_Release_Validation;
with Identity_Tools_Workflows;

procedure Identity_Tools is
   Architecture_Report : Identity_Tools_Architecture.Validation_Report;
   Capability_Report   : Identity_Tools_Capabilities.Validation_Report;
   Audit_Report        : Identity_Tools_Audit_Coverage.Validation_Report;
   Gap_Report          : Identity_Tools_Gap_Claims.Validation_Report;
   Crypto_Report       : Identity_Tools_Crypto_Validation.Validation_Report;
   Doc_Report          : Identity_Tools_Documentation.Validation_Report;
   Event_Report        : Identity_Tools_Events.Validation_Report;
   Invariant_Report    : Identity_Tools_Invariants.Validation_Report;
   Leak_Report         : Identity_Tools_Secret_Leaks.Scan_Report;
   Persisted_Report    : Identity_Tools_Persisted_Validation.Validation_Report;
   Proof_Report        : Identity_Tools_Proof_Validation.Validation_Report;
   Generated_Report    : Identity_Tools_Release_Reports.Generation_Report;
   Evidence_Report     : Identity_Tools_Evidence.Evidence_Report;
   Gates_Passed        : Boolean;
   Release_Report      : Identity_Tools_Release_Validation.Validation_Report;
   Workflow_Report     : Identity_Tools_Workflows.Validation_Report;
begin
   Ada.Text_IO.Put_Line
     ("identity_tools:"
      & Identity.Version.Crate_Name
      & ":"
      & Natural'Image (Identity.Version.V1_Major)
      & "."
      & Natural'Image (Identity.Version.V1_Minor)
      & "."
      & Natural'Image (Identity.Version.V1_Patch)
      & ":"
     & Identity.Version.Status);
   Ada.Text_IO.Put_Line
     ("identity_tools:release-artifacts:"
      & Natural'Image (Identity_Tools_Release_Artifacts.Required_Artifact_Count)
      & ":prohibited:"
      & Natural'Image (Identity_Tools_Release_Artifacts.Prohibited_Material_Count)
      & ":provenance-fields:"
      & Natural'Image (Identity_Tools_Release_Artifacts.Provenance_Field_Count));
   Identity_Tools_Release_Validation.Validate (Release_Report);
   Ada.Text_IO.Put_Line
     ("identity_tools:release-validation:"
      & Natural'Image (Release_Report.Artifact_Count)
      & ":required:"
      & Natural'Image (Release_Report.Required_Count)
      & ":sensitive:"
      & Natural'Image (Release_Report.Sensitive_Count)
      & ":prohibited:"
      & Natural'Image (Release_Report.Prohibited_Count)
      & ":provenance-fields:"
      & Natural'Image (Release_Report.Provenance_Field_Count)
      & ":missing-artifacts:"
      & Natural'Image (Release_Report.Missing_Artifacts)
      & ":missing-prohibited:"
      & Natural'Image (Release_Report.Missing_Prohibited)
      & ":missing-provenance:"
      & Natural'Image (Release_Report.Missing_Provenance));
   Ada.Text_IO.Put_Line
     ("identity_tools:persisted-formats:"
      & Natural'Image (Identity_Tools_Persisted_Formats.Format_Count)
      & ":fixtures:"
      & Natural'Image (Identity_Tools_Persisted_Formats.Fixture_Count));
   Identity_Tools_Persisted_Validation.Validate (Persisted_Report);
   Ada.Text_IO.Put_Line
     ("identity_tools:persisted-validation:"
      & Natural'Image (Persisted_Report.Format_Count)
      & ":fixtures:"
      & Natural'Image (Persisted_Report.Fixture_Count)
      & ":missing-formats:"
      & Natural'Image (Persisted_Report.Missing_Formats)
      & ":missing-fixtures:"
      & Natural'Image (Persisted_Report.Missing_Fixtures)
      & ":missing-requirements:"
      & Natural'Image (Persisted_Report.Missing_Requirements)
      & ":requirements:"
      & Natural'Image (Persisted_Report.Requirement_Count)
      & ":missing-files:"
      & Natural'Image (Persisted_Report.Missing_Fixture_Files));
   Identity_Tools_Crypto_Validation.Validate (Crypto_Report);
   Ada.Text_IO.Put_Line
     ("identity_tools:crypto-validation:"
      & Natural'Image (Crypto_Report.Algorithm_Count)
      & ":classes:"
      & Natural'Image (Crypto_Report.Class_Count)
      & ":implementations:"
      & Natural'Image (Crypto_Report.Implementation_Count)
      & ":format-versions:"
      & Natural'Image (Crypto_Report.Format_Version_Count)
      & ":constant-time:"
      & Natural'Image (Crypto_Report.Constant_Time_Count)
      & ":creation:"
      & Natural'Image (Crypto_Report.Creation_Count)
      & ":verification:"
      & Natural'Image (Crypto_Report.Verify_Count)
      & ":deprecated:"
      & Natural'Image (Crypto_Report.Deprecated_State_Count)
      & ":missing-algorithms:"
      & Natural'Image (Crypto_Report.Missing_Algorithms)
      & ":missing-fields:"
      & Natural'Image (Crypto_Report.Missing_Descriptor_Fields));
   Identity_Tools_Workflows.Validate (Workflow_Report);
   Ada.Text_IO.Put_Line
     ("identity_tools:workflows:"
      & Natural'Image (Workflow_Report.Workflow_Count)
      & ":gates:"
      & Natural'Image (Workflow_Report.Gate_Count)
      & ":missing-workflows:"
      & Natural'Image (Workflow_Report.Missing_Workflows)
      & ":missing-gates:"
      & Natural'Image (Workflow_Report.Missing_Gates)
      & ":missing-orchestrator:"
      & Natural'Image (Workflow_Report.Missing_Orchestrator)
      & ":missing-project-metadata:"
      & Natural'Image (Workflow_Report.Missing_Project_Metadata));
   Identity_Tools_Proof_Validation.Validate (Proof_Report);
   Ada.Text_IO.Put_Line
     ("identity_tools:proof-validation:"
      & Natural'Image (Proof_Report.Package_Count)
      & ":properties:"
      & Natural'Image (Proof_Report.Property_Count)
      & ":exclusions:"
      & Natural'Image (Proof_Report.Exclusion_Count)
      & ":justified-exclusions:"
      & Natural'Image (Proof_Report.Exclusion_Reasons)
      & ":empty-compensations:"
      & Natural'Image (Proof_Report.Empty_Compensations)
      & ":missing-packages:"
      & Natural'Image (Proof_Report.Missing_Packages)
      & ":missing-properties:"
      & Natural'Image (Proof_Report.Missing_Properties)
      & ":missing-gate:"
      & Natural'Image (Proof_Report.Missing_Gate)
      & ":missing-orchestrator:"
      & Natural'Image (Proof_Report.Missing_Orchestrator)
      & ":missing-baseline-rule:"
      & Natural'Image (Proof_Report.Missing_Baseline_Rule));
   Identity_Tools_Invariants.Validate (Invariant_Report);
   Ada.Text_IO.Put_Line
     ("identity_tools:invariants:"
      & Natural'Image (Invariant_Report.Invariant_Count)
      & ":required-tests:"
      & Natural'Image (Invariant_Report.Required_Test_Block_Count)
      & ":empty-required-tests:"
      & Natural'Image (Invariant_Report.Empty_Required_Test_Blocks)
      & ":severity:"
      & Natural'Image (Invariant_Report.Failure_Severity_Count)
      & ":test-names:"
      & Natural'Image (Invariant_Report.Required_Test_Names)
      & ":traced:"
      & Natural'Image (Invariant_Report.Traced_Required_Tests)
      & ":untraced:"
      & Natural'Image (Invariant_Report.Untraced_Required_Tests));
   Identity_Tools_Events.Validate (Event_Report);
   Ada.Text_IO.Put_Line
     ("identity_tools:events:"
      & Natural'Image (Event_Report.Registry_Event_Count)
      & ":public:"
      & Natural'Image (Event_Report.Public_Event_Count)
      & ":missing-public:"
      & Natural'Image (Event_Report.Missing_Public)
      & ":missing-registry:"
      & Natural'Image (Event_Report.Missing_Registry));
   Identity_Tools_Documentation.Validate (Doc_Report);
   Ada.Text_IO.Put_Line
     ("identity_tools:documentation:"
      & Natural'Image (Doc_Report.Documents_Checked)
      & ":required:"
      & Natural'Image (Doc_Report.Required_Documents)
      & ":missing-required:"
      & Natural'Image (Doc_Report.Missing_Required)
      & ":empty-required:"
      & Natural'Image (Doc_Report.Empty_Required)
      & ":referenced:"
      & Natural'Image (Doc_Report.Referenced_Documents)
      & ":missing-referenced:"
      & Natural'Image (Doc_Report.Missing_Referenced)
      & ":artifact-documents:"
      & Natural'Image (Doc_Report.Artifact_Documents)
      & ":missing-artifact-documents:"
      & Natural'Image (Doc_Report.Missing_Artifact_Docs)
      & ":placeholders:"
      & Natural'Image (Doc_Report.Placeholder_Hits)
      & ":public-areas:"
      & Natural'Image (Doc_Report.Public_Areas)
      & ":unmapped-areas:"
      & Natural'Image (Doc_Report.Unmapped_Areas)
      & ":missing-changelog-section:"
      & Natural'Image (Doc_Report.Missing_Changelog_Section));
   Identity_Tools_Architecture.Validate (Architecture_Report);
   Ada.Text_IO.Put_Line
     ("identity_tools:architecture:"
      & Natural'Image (Architecture_Report.Files_Checked)
      & ":internal:"
      & Natural'Image (Architecture_Report.Internal_Dependency_Hits)
      & ":crypto-imports:"
      & Natural'Image (Architecture_Report.Crypto_Import_Hits)
      & ":crypto-violations:"
      & Natural'Image (Architecture_Report.Crypto_Import_Violations)
      & ":boundary-terms:"
      & Natural'Image (Architecture_Report.Boundary_Term_Hits));
   Identity_Tools_Secret_Leaks.Scan (Leak_Report);
   Ada.Text_IO.Put_Line
     ("identity_tools:secret-leaks:"
      & Natural'Image (Leak_Report.Files_Checked)
      & ":canary-hits:"
      & Natural'Image (Leak_Report.Canary_Hits));
   Identity_Tools_Capabilities.Validate (Capability_Report);
   Ada.Text_IO.Put_Line
     ("identity_tools:capabilities:"
      & Natural'Image (Capability_Report.Advertised)
      & ":backed:"
      & Natural'Image (Capability_Report.Backed)
      & ":unbacked:"
      & Natural'Image (Capability_Report.Unbacked));

   Identity_Tools_Audit_Coverage.Validate (Audit_Report);
   Ada.Text_IO.Put_Line
     ("identity_tools:audit-coverage:"
      & Natural'Image (Audit_Report.Mutating_Operations)
      & ":audited:"
      & Natural'Image (Audit_Report.Audited_Operations)
      & ":unaudited:"
      & Natural'Image (Audit_Report.Unaudited_Operations)
      & ":mutating-primitives:"
      & Natural'Image (Audit_Report.Mutating_Primitives)
      & ":audited-overloads:"
      & Natural'Image (Audit_Report.Audited_Overloads)
      & ":bypass-overloads:"
      & Natural'Image (Audit_Report.Bypass_Overloads));

   Identity_Tools_Gap_Claims.Validate (Gap_Report);
   Ada.Text_IO.Put_Line
     ("identity_tools:gap-claims:"
      & Natural'Image (Gap_Report.Claims_Checked)
      & ":stale:"
      & Natural'Image (Gap_Report.Stale_Gap_Claims)
      & ":unrecorded:"
      & Natural'Image (Gap_Report.Missing_Suites));

   Identity_Tools_Evidence.Validate (Evidence_Report);
   Ada.Text_IO.Put_Line
     ("identity_tools:evidence:"
      & Natural'Image (Evidence_Report.Present)
      & ":passed:"
      & Natural'Image (Evidence_Report.Passed)
      & ":failed:"
      & Natural'Image (Evidence_Report.Failed)
      & ":missing:"
      & Natural'Image (Evidence_Report.Missing));

   Gates_Passed :=
     Identity_Tools_Audit_Coverage.Passed (Audit_Report)
     and then Identity_Tools_Gap_Claims.Passed (Gap_Report)
     and then Identity_Tools_Capabilities.Passed (Capability_Report)
     and then Identity_Tools_Evidence.Passed (Evidence_Report)
     and then Identity_Tools_Architecture.Passed (Architecture_Report)
     and then Identity_Tools_Crypto_Validation.Passed (Crypto_Report)
     and then Identity_Tools_Documentation.Passed (Doc_Report)
     and then Identity_Tools_Events.Passed (Event_Report)
     and then Identity_Tools_Invariants.Passed (Invariant_Report)
     and then Identity_Tools_Persisted_Validation.Passed (Persisted_Report)
     and then Identity_Tools_Proof_Validation.Passed (Proof_Report)
     and then Identity_Tools_Release_Validation.Passed (Release_Report)
     and then Identity_Tools_Secret_Leaks.Passed (Leak_Report)
     and then Identity_Tools_Workflows.Passed (Workflow_Report);

   if Gates_Passed then
      Identity_Tools_Release_Reports.Generate (Generated_Report);
   else
      Generated_Report := (Output_Count => 0, Write_Failures => 0, Skipped => 1);
   end if;
   Ada.Text_IO.Put_Line
     ("identity_tools:release-reports:"
      & Natural'Image (Generated_Report.Output_Count)
      & ":write-failures:"
      & Natural'Image (Generated_Report.Write_Failures)
      & ":skipped:"
      & Natural'Image (Generated_Report.Skipped));

   --  A failing gate must fail the run, not merely suppress report generation.
   if not Gates_Passed
     or else not Identity_Tools_Release_Reports.Passed (Generated_Report)
   then
      Ada.Text_IO.Put_Line ("identity_tools:result:failed");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Text_IO.Put_Line ("identity_tools:result:passed");
   end if;
end Identity_Tools;
