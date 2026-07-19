with Identity.Events.Envelopes;
with Identity.Identifiers.Entities;

package Identity.Audit.Records is
   pragma Pure;

   type Integrity_State is (Not_Configured, Verified, Failed);

   type Audit_Record is record
      Id         : Identity.Identifiers.Entities.Event_Id;
      Event      : Identity.Events.Envelopes.Event_Envelope;
      Durability : Identity.Audit.Audit_Durability := Identity.Audit.Durable;
      Integrity  : Integrity_State := Not_Configured;
   end record;
end Identity.Audit.Records;
