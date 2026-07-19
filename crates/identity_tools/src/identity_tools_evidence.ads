package Identity_Tools_Evidence is
   pragma Elaborate_Body;

   --  Evidence of an actually-executed suite. Each entry is written by the
   --  release orchestration script immediately after running the corresponding
   --  executable, and records that run's real outcome. The release reports are
   --  generated from these files rather than from declarations, so a suite
   --  that was never run cannot be reported as satisfied.
   type Evidence_Id is
     (AUnit_Suite,
      Conformance,
      Gate_Self_Tests,
      Proof,
      Examples);

   type Evidence_State is (Passed, Failed, Missing);

   function Name (Id : Evidence_Id) return String;
   function State (Id : Evidence_Id) return Evidence_State;
   function State_Image (Value : Evidence_State) return String;

   --  Free-text detail recorded alongside the outcome (counts, versions).
   function Detail (Id : Evidence_Id) return String;

   type Evidence_Report is record
      Present : Natural := 0;
      Passed  : Natural := 0;
      Failed  : Natural := 0;
      Missing : Natural := 0;
   end record;

   procedure Validate (Report : out Evidence_Report);
   function Passed (Report : Evidence_Report) return Boolean;
end Identity_Tools_Evidence;
