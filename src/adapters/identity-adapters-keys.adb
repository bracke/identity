package body Identity.Adapters.Keys is
   function Denial_For (Value : Key_Lookup_Result) return Key_Admission_Decision;

   function Denial_For (Value : Key_Lookup_Result) return Key_Admission_Decision is
      use type Identity.Crypto.Keys.Key_State;
   begin
      if Value.Status = Missing then
         return Reject_Missing;
      elsif Value.Status = Unavailable
        or else Value.Key.State = Identity.Crypto.Keys.Unavailable
      then
         return Reject_Unavailable;
      elsif Value.Status = Retired
        or else Value.Key.State = Identity.Crypto.Keys.Retired
      then
         return Reject_Retired;
      elsif Value.Status = Revoked
        or else Value.Key.State = Identity.Crypto.Keys.Revoked
      then
         return Reject_Revoked;
      else
         return Reject_Missing;
      end if;
   end Denial_For;

   function Active_Creation_Key
     (Key_Id : Identity.Text.Bounded.Bounded_Text;
      Domain : Identity.Identifiers.Registry.Registry_Id) return Key_Lookup_Result
   is
   begin
      return
        (Status => Found,
         Key    =>
           (Key_Id => Key_Id,
            Domain => Domain,
            State  => Identity.Crypto.Keys.Active));
   end Active_Creation_Key;

   function Admit_For_Creation
     (Value : Key_Lookup_Result;
      Domain : Identity.Identifiers.Registry.Registry_Id)
      return Key_Admission_Decision
   is
      use type Identity.Crypto.Keys.Key_State;
      use type Identity.Identifiers.Registry.Registry_Id;
   begin
      if Value.Status not in Found | Verification_Only then
         return Denial_For (Value);
      elsif Value.Key.Domain /= Domain then
         return Reject_Domain_Mismatch;
      elsif Value.Status = Verification_Only
        or else Value.Key.State = Identity.Crypto.Keys.Verification_Only
      then
         return Reject_Verification_Only_For_Creation;
      elsif Identity.Crypto.Keys.Can_Create (Value.Key) then
         return Allow_Creation;
      else
         return Denial_For (Value);
      end if;
   end Admit_For_Creation;

   function Admit_For_Verification
     (Value : Key_Lookup_Result;
      Domain : Identity.Identifiers.Registry.Registry_Id)
      return Key_Admission_Decision
   is
      use type Identity.Identifiers.Registry.Registry_Id;
   begin
      if Value.Status not in Found | Verification_Only then
         return Denial_For (Value);
      elsif Value.Key.Domain /= Domain then
         return Reject_Domain_Mismatch;
      elsif Identity.Crypto.Keys.Can_Verify (Value.Key) then
         return Allow_Verification;
      else
         return Denial_For (Value);
      end if;
   end Admit_For_Verification;
end Identity.Adapters.Keys;
