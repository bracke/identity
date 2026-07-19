package Identity.Internal.Orchestration is
   pragma Pure;

   type Operation_Phase is
     (Input_Checked,
      Policy_Captured,
      Snapshot_Read,
      Verification_Performed,
      Transition_Staged,
      Transition_Committed,
      Post_Commit_Ready);

   type Orchestration_Status is (Ready, Cancelled, Deadline_Exceeded, Capacity_Exceeded, Faulted);
end Identity.Internal.Orchestration;
