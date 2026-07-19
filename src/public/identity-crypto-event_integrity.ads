with Identity.Crypto.Capabilities;
with Identity.Identifiers.Registry;

package Identity.Crypto.Event_Integrity is
   pragma Pure;
   use type Identity.Crypto.Capabilities.Capability_State;

   type Event_Integrity_Status is
     (Verified,
      Not_Verified,
      Not_Configured,
      Missing_Capability);

   type Event_Integrity_Service is record
      Capability : Identity.Crypto.Capabilities.Capability_State :=
        Identity.Crypto.Capabilities.Missing;
      Algorithm  : Identity.Identifiers.Registry.Registry_Id;
   end record;

   function Configured (Value : Event_Integrity_Service) return Boolean is
     (Value.Capability = Identity.Crypto.Capabilities.Available);

   function Verification_Accepted
     (Value : Event_Integrity_Status) return Boolean is
     (Value = Verified);
   function Verification_Rejected
     (Value : Event_Integrity_Status) return Boolean is
     (Value = Not_Verified);
   function Not_Configured_Status
     (Value : Event_Integrity_Status) return Boolean is
     (Value = Not_Configured);
   function Missing_Cryptographic_Capability
     (Value : Event_Integrity_Status) return Boolean is
     (Value = Missing_Capability);
   function Operational_Failure
     (Value : Event_Integrity_Status) return Boolean is
     (Value = Not_Configured or else Value = Missing_Capability);
end Identity.Crypto.Event_Integrity;
