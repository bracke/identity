package Identity.Errors is
   pragma Pure;

   type Error_Category is
     (Success,
      Rejection,
      Additional_Action_Required,
      Conflict,
      Invalid_Input,
      Unsupported,
      Resource_Limit,
      Operational_Failure,
      Internal_Invariant_Failure);

   type Retry_Class is (Do_Not_Retry, Retry_Same_Request, Retry_With_New_Input, Retry_After);
   type Cause_Class is (Caller_Input, Credential_State, Account_State, Repository, Cryptographic_Service, Policy, Bug);

   subtype Stable_Code is String (1 .. 64);
   subtype Message_Id is String (1 .. 96);

   type Error_Value is record
      Category       : Error_Category := Success;
      Retry          : Retry_Class := Do_Not_Retry;
      Cause          : Cause_Class := Caller_Input;
      Operation_Set  : Boolean := False;
      Correlation_Set : Boolean := False;
   end record;

   function Is_Failure (Value : Error_Value) return Boolean is (Value.Category /= Success);
end Identity.Errors;
