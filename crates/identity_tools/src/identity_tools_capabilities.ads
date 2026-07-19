package Identity_Tools_Capabilities is
   pragma Elaborate_Body;

   --  A repository capability that the adapter advertises as True is a promise
   --  the operations layer relies on: Admit_Transaction and Admit_Command make
   --  admission decisions from these flags. A flag that nothing implements is
   --  the same class of defect as a conformance harness that hardcodes
   --  "passed" -- a declaration standing in for a behaviour.
   --
   --  This gate reads the advertised profile out of the capabilities adapter
   --  and, for each flag set True, requires that the SPI primitive backing it
   --  is actually called from the operations layer.
   type Validation_Report is record
      Advertised    : Natural := 0;
      Backed        : Natural := 0;
      Unbacked      : Natural := 0;
      Missing_Source : Natural := 0;
   end record;

   procedure Validate (Report : out Validation_Report);
   function Passed (Report : Validation_Report) return Boolean;
end Identity_Tools_Capabilities;
