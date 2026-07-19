package Identity_Tools_Secret_Leaks is
   pragma Elaborate_Body;

   type Scan_Report is record
      Files_Checked : Natural := 0;
      Canary_Hits   : Natural := 0;
   end record;

   procedure Scan (Report : out Scan_Report);
   function Passed (Report : Scan_Report) return Boolean;
end Identity_Tools_Secret_Leaks;
