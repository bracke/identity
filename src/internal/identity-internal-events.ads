package Identity.Internal.Events is
   pragma Pure;

   type Event_Stage is (Not_Staged, Staged_With_Transition, Committed, Publication_Ready);
   type Event_Status is (Accepted, Rejected_Secret_Data, Capacity_Exceeded, Integrity_Unavailable);
end Identity.Internal.Events;
