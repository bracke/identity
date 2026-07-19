with Identity.Events.Envelopes;
with Identity.Identifiers.Operations;

package Identity.Adapters.Repositories.Events is
   pragma Pure;

   type Event_Append_Status is (Staged, Capacity_Exceeded, Infrastructure_Failure);

   function Staged_Status (Status : Event_Append_Status) return Boolean is
     (Status = Staged);

   function Capacity_Rejected (Status : Event_Append_Status) return Boolean is
     (Status = Capacity_Exceeded);

   function Infrastructure_Failed (Status : Event_Append_Status) return Boolean is
     (Status = Infrastructure_Failure);

   function Operational_Failure (Status : Event_Append_Status) return Boolean is
     (Status in Capacity_Exceeded | Infrastructure_Failure);

   type Mandatory_Event_Command is record
      Operation_Id : Identity.Identifiers.Operations.Operation_Id;
      Event        : Identity.Events.Envelopes.Event_Envelope;
   end record;
end Identity.Adapters.Repositories.Events;
