package Identity_Tools_Workflows is
   pragma Elaborate_Body;

   type Validation_Report is record
      Workflow_Count        : Natural := 0;
      Gate_Count            : Natural := 0;
      Missing_Workflows     : Natural := 0;
      Missing_Gates         : Natural := 0;
      Missing_Orchestrator  : Natural := 0;
      Missing_Project_Metadata : Natural := 0;
   end record;

   procedure Validate (Report : out Validation_Report);
   function Passed (Report : Validation_Report) return Boolean;
end Identity_Tools_Workflows;
