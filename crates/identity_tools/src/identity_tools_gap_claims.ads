package Identity_Tools_Gap_Claims is
   pragma Elaborate_Body;

   --  tools/release-gates.txt drifted twice in this project's history: first
   --  by claiming coverage that did not exist, later by still listing suites
   --  as missing after they had been written. Both are the same failure --
   --  a document asserting something about the code that nothing checks.
   --
   --  This gate cross-checks the machine-checkable half of that document: for
   --  each dedicated suite, whether the AUnit suite actually carries
   --  assertions with that prefix must agree with what the gaps section says.
   type Validation_Report is record
      Claims_Checked  : Natural := 0;
      Stale_Gap_Claims : Natural := 0;
      Missing_Suites  : Natural := 0;
      Missing_Source  : Natural := 0;
   end record;

   procedure Validate (Report : out Validation_Report);
   function Passed (Report : Validation_Report) return Boolean;
end Identity_Tools_Gap_Claims;
