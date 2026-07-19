package Identity.Results is
   pragma Pure;

   type Operation_Status is
     (Succeeded,
      Rejected,
      Additional_Factor_Required,
      Password_Change_Required,
      Verification_Required,
      Recovery_Action_Required,
      Throttled,
      Conflict,
      Invalid_Input,
      Unsupported,
      Operational_Failure,
      Resource_Limit,
      Internal_Invariant_Failure);

   function Successful (Status : Operation_Status) return Boolean is
     (Status = Succeeded);

   function Ordinary_Rejection (Status : Operation_Status) return Boolean is
     (Status = Rejected);

   function Additional_Action_Required
     (Status : Operation_Status) return Boolean is
     (Status in Additional_Factor_Required
              | Password_Change_Required
              | Verification_Required
              | Recovery_Action_Required);

   function Throttle_Rejection (Status : Operation_Status) return Boolean is
     (Status = Throttled);

   function Conflict_Status (Status : Operation_Status) return Boolean is
     (Status = Conflict);

   function Invalid_Input_Status (Status : Operation_Status) return Boolean is
     (Status = Invalid_Input);

   function Unsupported_Status (Status : Operation_Status) return Boolean is
     (Status = Unsupported);

   function Operational (Status : Operation_Status) return Boolean is
     (Status in Operational_Failure
              | Resource_Limit
              | Internal_Invariant_Failure);

   function Resource_Limited (Status : Operation_Status) return Boolean is
     (Status = Resource_Limit);

   function Internal_Invariant (Status : Operation_Status) return Boolean is
     (Status = Internal_Invariant_Failure);

   function Disclosure_Generic_Rejection
     (Status : Operation_Status) return Boolean is
     (Status in Rejected
              | Additional_Factor_Required
              | Password_Change_Required
              | Verification_Required
              | Recovery_Action_Required
              | Throttled);
end Identity.Results;
