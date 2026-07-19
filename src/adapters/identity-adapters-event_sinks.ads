with Identity.Events.Envelopes;
with Identity.Events.Policies;

package Identity.Adapters.Event_Sinks is
   type Publication_Status is (Accepted, Retryable_Failure, Permanent_Failure);
   type Publication_Admission is
     (Publication_Allowed,
      Publication_Status_Rejected,
      Publication_Timing_Rejected,
      Publication_Policy_Rejected);

   function Accepted_Status (Status : Publication_Status) return Boolean is
     (Status = Accepted);

   function Retryable (Status : Publication_Status) return Boolean is
     (Status = Retryable_Failure);

   function Permanent (Status : Publication_Status) return Boolean is
     (Status = Permanent_Failure);

   function Publication_Failed (Status : Publication_Status) return Boolean is
     (Status in Retryable_Failure | Permanent_Failure);

   function Admission_Accepted
     (Admission : Publication_Admission) return Boolean is
     (Admission = Publication_Allowed);

   function Status_Rejected
     (Admission : Publication_Admission) return Boolean is
     (Admission = Publication_Status_Rejected);

   function Timing_Rejected
     (Admission : Publication_Admission) return Boolean is
     (Admission = Publication_Timing_Rejected);

   function Policy_Rejected
     (Admission : Publication_Admission) return Boolean is
     (Admission = Publication_Policy_Rejected);

   type Event_Publication is record
      Event  : Identity.Events.Envelopes.Event_Envelope;
      Status : Publication_Status := Accepted;
      After_Commit : Boolean := True;
   end record;

   function Publishable (Value : Event_Publication) return Boolean is
     (Value.After_Commit and then Value.Status = Accepted);

   function Admit_For_Publication
     (Value  : Event_Publication;
      Policy : Identity.Events.Policies.Event_Policy) return Publication_Admission is
     (if not Identity.Events.Policies.Valid (Policy) then
        Publication_Policy_Rejected
      elsif not Value.After_Commit then
        Publication_Timing_Rejected
      elsif Value.Status /= Accepted then
        Publication_Status_Rejected
      else
        Publication_Allowed);
end Identity.Adapters.Event_Sinks;
