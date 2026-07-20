package Identity_Tools_Events is
   pragma Elaborate_Body;

   type Validation_Report is record
      Registry_Event_Count : Natural := 0;
      Public_Event_Count   : Natural := 0;
      --  Entries present in the registry that this gate does not know about.
      --  Without this the registry could accumulate identifiers with no public
      --  constant behind them and nothing would say so: the gate checked that
      --  every known identifier appears in both places, never that the
      --  registry contains nothing else.
      Unknown_Registry_Entries : Natural := 0;
      Missing_Public       : Natural := 0;
      Missing_Registry     : Natural := 0;
   end record;

   procedure Validate (Report : out Validation_Report);
   function Passed (Report : Validation_Report) return Boolean;
end Identity_Tools_Events;
