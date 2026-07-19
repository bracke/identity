package Identity_Tools_Events is
   pragma Elaborate_Body;

   type Validation_Report is record
      Registry_Event_Count : Natural := 0;
      Public_Event_Count   : Natural := 0;
      Missing_Public       : Natural := 0;
      Missing_Registry     : Natural := 0;
   end record;

   procedure Validate (Report : out Validation_Report);
   function Passed (Report : Validation_Report) return Boolean;
end Identity_Tools_Events;
