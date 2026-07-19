package Identity_Tools_Release_Reports is
   pragma Elaborate_Body;

   type Generation_Report is record
      Output_Count   : Natural := 0;
      Write_Failures : Natural := 0;
      Skipped        : Natural := 0;
   end record;

   procedure Generate (Report : out Generation_Report);
   function Passed (Report : Generation_Report) return Boolean;
end Identity_Tools_Release_Reports;
