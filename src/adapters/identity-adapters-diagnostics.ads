with Identity.Diagnostics;
with Identity.Events.Classification;

package Identity.Adapters.Diagnostics is
   type Diagnostic_Sink_Status is (Accepted, Redacted, Rejected);

   function Accepted_Status (Status : Diagnostic_Sink_Status) return Boolean is
     (Status = Accepted);

   function Redacted_Status (Status : Diagnostic_Sink_Status) return Boolean is
     (Status = Redacted);

   function Rejected_Status (Status : Diagnostic_Sink_Status) return Boolean is
     (Status = Rejected);

   function Sink_Received (Status : Diagnostic_Sink_Status) return Boolean is
     (Status in Accepted | Redacted);

   type Diagnostic_Submission is record
      Diagnostic : Identity.Diagnostics.Diagnostic_Record;
      Class  : Identity.Events.Classification.Event_Data_Class :=
        Identity.Events.Classification.Operational;
   end record;

   function Accepts (Value : Diagnostic_Submission) return Diagnostic_Sink_Status;
end Identity.Adapters.Diagnostics;
