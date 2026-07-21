package Identity_Tools_Facts is
   pragma Elaborate_Body;

   --  The gates document quotes numbers about this crate -- how many event
   --  types exist, how many operations mutate and how many of those are
   --  audited, how many overloads remain reachable without an audit context.
   --  Every one of those has drifted at least once, because nothing connected
   --  the prose to the tool that computes it.
   --
   --  Rather than check the prose, generate it. This module renders the
   --  measured figures as a fenced block and requires the stored document to
   --  contain exactly that text, using Project_Tools.Generated_Docs. A change
   --  to the code that moves a number fails the release check until the
   --  document is regenerated, and the failure prints the text to paste.
   type Validation_Report is record
      Blocks_Checked : Natural := 0;
      Stale_Blocks   : Natural := 0;
      Missing_Blocks : Natural := 0;
   end record;

   --  Render the current facts block from measured values.
   function Rendered
     (Event_Types         : Natural;
      Mutating_Operations : Natural;
      Audited_Operations  : Natural;
      Exempt_Operations   : Natural;
      Audited_Overloads   : Natural;
      Bypass_Overloads    : Natural;
      Proved_Packages     : Natural;
      Invariants          : Natural;
      Test_Routines       : Natural) return String;

   procedure Validate
     (Report              : out Validation_Report;
      Event_Types         : Natural;
      Mutating_Operations : Natural;
      Audited_Operations  : Natural;
      Exempt_Operations   : Natural;
      Audited_Overloads   : Natural;
      Bypass_Overloads    : Natural;
      Proved_Packages     : Natural;
      Invariants          : Natural;
      Test_Routines       : Natural);

   function Passed (Report : Validation_Report) return Boolean;
end Identity_Tools_Facts;
