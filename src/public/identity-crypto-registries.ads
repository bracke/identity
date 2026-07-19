with Identity.Crypto.Algorithms;

package Identity.Crypto.Registries is
   pragma Pure;

   type Algorithm_Registration_Status is
     (Registered,
      Creation_Disabled,
      Verification_Disabled,
      Retired);

   function Creation_Status
     (Value : Identity.Crypto.Algorithms.Algorithm_Descriptor)
      return Algorithm_Registration_Status;

   function Verification_Status
     (Value : Identity.Crypto.Algorithms.Algorithm_Descriptor)
      return Algorithm_Registration_Status;

   function Registered_Status
     (Value : Algorithm_Registration_Status) return Boolean is
     (Value = Registered);
   function Creation_Disabled_Status
     (Value : Algorithm_Registration_Status) return Boolean is
     (Value = Creation_Disabled);
   function Verification_Disabled_Status
     (Value : Algorithm_Registration_Status) return Boolean is
     (Value = Verification_Disabled);
   function Retired_Status
     (Value : Algorithm_Registration_Status) return Boolean is
     (Value = Retired);
   function Admission_Rejected
     (Value : Algorithm_Registration_Status) return Boolean is
     (Value /= Registered);
end Identity.Crypto.Registries;
