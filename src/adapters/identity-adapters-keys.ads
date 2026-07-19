with Identity.Crypto.Keys;
with Identity.Identifiers.Registry;
with Identity.Text.Bounded;

package Identity.Adapters.Keys is
   type Key_Lookup_Status is (Found, Verification_Only, Retired, Revoked, Unavailable, Missing);
   type Key_Admission_Decision is
     (Allow_Creation,
      Allow_Verification,
      Reject_Missing,
      Reject_Unavailable,
      Reject_Retired,
      Reject_Revoked,
      Reject_Verification_Only_For_Creation,
      Reject_Domain_Mismatch);

   function Found_Status (Status : Key_Lookup_Status) return Boolean is
     (Status = Found);

   function Verification_Only_Status (Status : Key_Lookup_Status) return Boolean is
     (Status = Verification_Only);

   function Retired_Status (Status : Key_Lookup_Status) return Boolean is
     (Status = Retired);

   function Revoked_Status (Status : Key_Lookup_Status) return Boolean is
     (Status = Revoked);

   function Unavailable_Status (Status : Key_Lookup_Status) return Boolean is
     (Status = Unavailable);

   function Missing_Status (Status : Key_Lookup_Status) return Boolean is
     (Status = Missing);

   function Lookup_Usable_For_Verification (Status : Key_Lookup_Status) return Boolean is
     (Status in Found | Verification_Only);

   function Lookup_Rejected (Status : Key_Lookup_Status) return Boolean is
     (Status in Retired | Revoked | Unavailable | Missing);

   function Creation_Allowed (Decision : Key_Admission_Decision) return Boolean is
     (Decision = Allow_Creation);

   function Verification_Allowed (Decision : Key_Admission_Decision) return Boolean is
     (Decision = Allow_Verification);

   function Admission_Rejected (Decision : Key_Admission_Decision) return Boolean is
     (Decision not in Allow_Creation | Allow_Verification);

   function Lifecycle_Rejected (Decision : Key_Admission_Decision) return Boolean is
     (Decision in Reject_Retired | Reject_Revoked);

   function Availability_Rejected (Decision : Key_Admission_Decision) return Boolean is
     (Decision in Reject_Missing | Reject_Unavailable);

   function Domain_Rejected (Decision : Key_Admission_Decision) return Boolean is
     (Decision = Reject_Domain_Mismatch);

   type Key_Lookup_Result is record
      Status : Key_Lookup_Status := Missing;
      Key    : Identity.Crypto.Keys.Key_Reference;
   end record;

   function Active_Creation_Key
     (Key_Id : Identity.Text.Bounded.Bounded_Text;
      Domain : Identity.Identifiers.Registry.Registry_Id) return Key_Lookup_Result;

   function May_Verify (Value : Key_Lookup_Result) return Boolean is
     (Identity.Crypto.Keys.Can_Verify (Value.Key)
      and then Value.Status in Found | Verification_Only);

   function Admit_For_Creation
     (Value : Key_Lookup_Result;
      Domain : Identity.Identifiers.Registry.Registry_Id)
      return Key_Admission_Decision;

   function Admit_For_Verification
     (Value : Key_Lookup_Result;
      Domain : Identity.Identifiers.Registry.Registry_Id)
      return Key_Admission_Decision;
end Identity.Adapters.Keys;
