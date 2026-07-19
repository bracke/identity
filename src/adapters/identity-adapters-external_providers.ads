with Identity.External_Providers.Assertions;
with Identity.Identifiers.Registry;
with Identity.Text.Bounded;

package Identity.Adapters.External_Providers is
   type Assertion_Adapter_Status is
     (Validated,
      Invalid,
      Expired,
      Audience_Mismatch,
      Nonce_Mismatch,
      Provider_Untrusted,
      Replay_Suspected,
      Missing_Capability,
      Infrastructure_Failure);

   type Assertion_Adapter_Result is record
      Status  : Assertion_Adapter_Status := Missing_Capability;
      Profile : Identity.Identifiers.Registry.Registry_Id;
      Issuer  : Identity.Text.Bounded.Bounded_Text;
      Subject : Identity.Text.Bounded.Bounded_Text;
      Assertion : Identity.External_Providers.Assertions.Normalized_Assertion;
   end record;

   function Accepts_For_Core (Status : Assertion_Adapter_Status) return Boolean is
     (Status = Validated);

   function Validated_Status (Status : Assertion_Adapter_Status) return Boolean is
     (Status = Validated);
   function Invalid_Status (Status : Assertion_Adapter_Status) return Boolean is
     (Status = Invalid);
   function Expired_Status (Status : Assertion_Adapter_Status) return Boolean is
     (Status = Expired);
   function Audience_Rejected (Status : Assertion_Adapter_Status) return Boolean is
     (Status = Audience_Mismatch);
   function Nonce_Rejected (Status : Assertion_Adapter_Status) return Boolean is
     (Status = Nonce_Mismatch);
   function Provider_Rejected (Status : Assertion_Adapter_Status) return Boolean is
     (Status = Provider_Untrusted);
   function Replay_Rejected (Status : Assertion_Adapter_Status) return Boolean is
     (Status = Replay_Suspected);
   function Missing_Capability_Status
     (Status : Assertion_Adapter_Status) return Boolean is
     (Status = Missing_Capability);
   function Infrastructure_Failed
     (Status : Assertion_Adapter_Status) return Boolean is
     (Status = Infrastructure_Failure);
   function Adapter_Rejected (Status : Assertion_Adapter_Status) return Boolean is
     (Status in Invalid
              | Expired
              | Audience_Mismatch
              | Nonce_Mismatch
              | Provider_Untrusted
              | Replay_Suspected);
   function Operational_Failure
     (Status : Assertion_Adapter_Status) return Boolean is
     (Status in Missing_Capability | Infrastructure_Failure);
end Identity.Adapters.External_Providers;
