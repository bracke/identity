with Identity.Limits;
with Identity.Policies.Snapshots;

package Identity.Operations.Budgets is
   pragma Pure;

   subtype Operation_Budget is Identity.Policies.Snapshots.Resource_Budget;

   type Budget_Dimension is
     (Repository_Reads,
      Repository_Writes,
      Entities_Loaded,
      Cryptographic_Operations,
      Password_History_Checks,
      Factor_Challenges,
      Events,
      Event_Attributes,
      Collection_Capacity,
      Retry_Count,
      Input_Bytes,
      Output_Bytes);

   type Budget_Admission_Status is (Within_Limits, Limit_Exceeded);

   type Budget_Admission is record
      Status    : Budget_Admission_Status := Within_Limits;
      Dimension : Budget_Dimension := Repository_Reads;
      Requested : Natural := 0;
      Limit     : Natural := 0;
   end record;

   function Within
     (Requested : Operation_Budget;
      Limits    : Operation_Budget) return Boolean;
   function Admit
     (Requested : Operation_Budget;
      Limits    : Operation_Budget) return Budget_Admission;

   function Hard_Limits return Operation_Budget is
     (Repository_Reads => Identity.Limits.Max_Repository_Reads,
      Repository_Writes => Identity.Limits.Max_Repository_Writes,
      Entities_Loaded => Identity.Limits.Max_Entities_Loaded,
      Cryptographic_Operations => Identity.Limits.Max_Cryptographic_Operations,
      Password_History_Checks => Identity.Limits.Max_Password_History_Checks,
      Factor_Challenges => Identity.Limits.Max_Factor_Challenges,
      Events => Identity.Limits.Max_Events_Per_Operation,
      Event_Attributes => Identity.Limits.Max_Event_Attributes,
      Collection_Capacity => Identity.Limits.Max_Collection_Capacity,
      Retry_Count => Identity.Limits.Max_Operation_Retries,
      Input_Bytes => Identity.Limits.Max_Input_Bytes,
      Output_Bytes => Identity.Limits.Max_Output_Bytes);

   function Within_Hard_Limits (Requested : Operation_Budget) return Boolean is
     (Within (Requested, Hard_Limits));

   function Admit_Hard_Limits
     (Requested : Operation_Budget) return Budget_Admission is
     (Admit (Requested, Hard_Limits));

   function Accepted
     (Status : Budget_Admission_Status) return Boolean is
     (Status = Within_Limits);

   function Rejected
     (Status : Budget_Admission_Status) return Boolean is
     (Status = Limit_Exceeded);

   function Accepted
     (Admission : Budget_Admission) return Boolean is
     (Admission.Status = Within_Limits);

   function Rejected
     (Admission : Budget_Admission) return Boolean is
     (Admission.Status = Limit_Exceeded);

   function Exceeded
     (Admission : Budget_Admission;
      Dimension : Budget_Dimension) return Boolean is
     (Admission.Status = Limit_Exceeded
      and then Admission.Dimension = Dimension);

   function Exceeds_Hard_Limit
     (Requested : Operation_Budget;
      Dimension : Budget_Dimension) return Boolean is
     (Exceeded (Admit_Hard_Limits (Requested), Dimension));

   function Has_Bounded_Detail
     (Admission : Budget_Admission) return Boolean is
     (Admission.Status = Within_Limits
      or else Admission.Requested > Admission.Limit);
end Identity.Operations.Budgets;
