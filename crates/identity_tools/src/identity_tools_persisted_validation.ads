package Identity_Tools_Persisted_Validation is
   pragma Elaborate_Body;

   type Validation_Report is record
      Format_Count          : Natural := 0;
      Fixture_Count         : Natural := 0;
      Missing_Formats       : Natural := 0;
      Missing_Fixtures      : Natural := 0;
      Missing_Requirements  : Natural := 0;
      Requirement_Count      : Natural := 0;
      Missing_Fixture_Files : Natural := 0;
   end record;

   procedure Validate (Report : out Validation_Report);
   function Passed (Report : Validation_Report) return Boolean;
end Identity_Tools_Persisted_Validation;
