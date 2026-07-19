package Identity_Tools_Release_Validation is
   pragma Elaborate_Body;

   type Validation_Report is record
      Artifact_Count          : Natural := 0;
      Required_Count          : Natural := 0;
      Sensitive_Count         : Natural := 0;
      Prohibited_Count        : Natural := 0;
      Provenance_Field_Count  : Natural := 0;
      Missing_Artifacts       : Natural := 0;
      Missing_Prohibited      : Natural := 0;
      Missing_Provenance      : Natural := 0;
   end record;

   procedure Validate (Report : out Validation_Report);
   function Passed (Report : Validation_Report) return Boolean;
end Identity_Tools_Release_Validation;
