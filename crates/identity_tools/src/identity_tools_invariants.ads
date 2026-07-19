package Identity_Tools_Invariants is
   pragma Elaborate_Body;

   type Validation_Report is record
      Invariant_Count            : Natural := 0;
      Required_Test_Block_Count  : Natural := 0;
      Empty_Required_Test_Blocks : Natural := 0;
      Failure_Severity_Count     : Natural := 0;
   end record;

   procedure Validate (Report : out Validation_Report);
   function Passed (Report : Validation_Report) return Boolean;
end Identity_Tools_Invariants;
