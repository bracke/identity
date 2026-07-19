package Identity_Tools_Crypto_Validation is
   pragma Elaborate_Body;

   type Validation_Report is record
      Algorithm_Count             : Natural := 0;
      Class_Count                 : Natural := 0;
      Implementation_Count        : Natural := 0;
      Format_Version_Count        : Natural := 0;
      Constant_Time_Count         : Natural := 0;
      Creation_Count              : Natural := 0;
      Verify_Count                : Natural := 0;
      Deprecated_State_Count      : Natural := 0;
      Missing_Algorithms          : Natural := 0;
      Missing_Descriptor_Fields   : Natural := 0;
   end record;

   procedure Validate (Report : out Validation_Report);
   function Passed (Report : Validation_Report) return Boolean;
end Identity_Tools_Crypto_Validation;
