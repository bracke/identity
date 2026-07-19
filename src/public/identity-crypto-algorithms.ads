with Identity.Identifiers.Registry;
with Identity.Versions;

package Identity.Crypto.Algorithms is
   pragma Pure;

   type Algorithm_Class is
     (Entropy_Source,
      Password_Hashing,
      Secret_Verifier,
      MAC,
      Constant_Time_Comparison,
      One_Time_Password,
      Event_Integrity,
      Key_Provider);

   type Deprecation_State is (Current, Deprecated, Retired);

   type Algorithm_Descriptor is record
      Id                  : Identity.Identifiers.Registry.Registry_Id;
      Class               : Algorithm_Class := Secret_Verifier;
      Implementation      : Identity.Versions.Format_Version := 1;
      Minimum_Format      : Identity.Versions.Format_Version := 1;
      Maximum_Format      : Identity.Versions.Format_Version := 1;
      Maximum_Output_Bytes : Natural range 0 .. 4096 := 128;
      Constant_Time_Verify : Boolean := False;
      Creation_Allowed    : Boolean := False;
      Verification_Allowed : Boolean := False;
      Deprecation         : Deprecation_State := Current;
   end record;

   function Can_Create (Value : Algorithm_Descriptor) return Boolean is
     (Value.Creation_Allowed and then Value.Deprecation = Current);
   function Can_Verify (Value : Algorithm_Descriptor) return Boolean is
     (Value.Verification_Allowed and then Value.Deprecation /= Retired);

   function Current_State (Value : Deprecation_State) return Boolean is
     (Value = Current);
   function Deprecated_State (Value : Deprecation_State) return Boolean is
     (Value = Deprecated);
   function Retired_State (Value : Deprecation_State) return Boolean is
     (Value = Retired);
   function Creation_Allowed_By_State
     (Value : Deprecation_State) return Boolean is
     (Value = Current);
   function Verification_Allowed_By_State
     (Value : Deprecation_State) return Boolean is
     (Value /= Retired);
end Identity.Crypto.Algorithms;
