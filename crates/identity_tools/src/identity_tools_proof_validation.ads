package Identity_Tools_Proof_Validation is
   pragma Elaborate_Body;

   type Validation_Report is record
      Package_Count       : Natural := 0;
      Property_Count      : Natural := 0;
      Exclusion_Count     : Natural := 0;
      --  An excluded package is acceptable only when it states why it cannot
      --  be proved and names the tests that compensate. Forbidding exclusions
      --  outright just pushes them into a silently unanalysed state.
      Exclusion_Reasons   : Natural := 0;
      Empty_Compensations : Natural := 0;
      Missing_Packages    : Natural := 0;
      Missing_Properties  : Natural := 0;
      Missing_Gate        : Natural := 0;
      Missing_Orchestrator : Natural := 0;
      Missing_Baseline_Rule : Natural := 0;
   end record;

   procedure Validate (Report : out Validation_Report);
   function Passed (Report : Validation_Report) return Boolean;
end Identity_Tools_Proof_Validation;
