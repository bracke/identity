package body Identity.Crypto.Registries is
   use type Identity.Crypto.Algorithms.Deprecation_State;

   function Creation_Status
     (Value : Identity.Crypto.Algorithms.Algorithm_Descriptor)
      return Algorithm_Registration_Status
   is
   begin
      if Value.Deprecation = Identity.Crypto.Algorithms.Retired then
         return Retired;
      elsif Value.Deprecation = Identity.Crypto.Algorithms.Deprecated
        or else not Value.Creation_Allowed
      then
         return Creation_Disabled;
      else
         return Registered;
      end if;
   end Creation_Status;

   function Verification_Status
     (Value : Identity.Crypto.Algorithms.Algorithm_Descriptor)
      return Algorithm_Registration_Status
   is
   begin
      if Value.Deprecation = Identity.Crypto.Algorithms.Retired then
         return Retired;
      elsif not Value.Verification_Allowed then
         return Verification_Disabled;
      else
         return Registered;
      end if;
   end Verification_Status;
end Identity.Crypto.Registries;
