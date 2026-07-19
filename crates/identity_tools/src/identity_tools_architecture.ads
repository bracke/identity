package Identity_Tools_Architecture is
   pragma Elaborate_Body;

   type Validation_Report is record
      Files_Checked             : Natural := 0;
      Internal_Dependency_Hits  : Natural := 0;
      Crypto_Import_Hits        : Natural := 0;
      Crypto_Import_Violations  : Natural := 0;
      Boundary_Term_Hits        : Natural := 0;
   end record;

   procedure Validate (Report : out Validation_Report);
   function Passed (Report : Validation_Report) return Boolean;
end Identity_Tools_Architecture;
