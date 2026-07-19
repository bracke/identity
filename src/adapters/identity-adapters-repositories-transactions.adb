with Identity.Errors;

package body Identity.Adapters.Repositories.Transactions is
   function Failure
     (State : Identity.Adapters.Repositories.Context_State;
      Code  : Identity.Adapters.Repositories.Failures.Repository_Failure_Code)
      return Transaction_Result is
     ((State => State,
       Failure =>
         (Code => Code,
          Error =>
            (Category => Identity.Errors.Operational_Failure,
             Retry => Identity.Errors.Retry_Same_Request,
             Cause => Identity.Errors.Repository,
             Operation_Set => False,
             Correlation_Set => False))));

   function Success
     (State : Identity.Adapters.Repositories.Context_State)
      return Transaction_Result is
     ((State => State,
       Failure =>
         (Code => Identity.Adapters.Repositories.Failures.No_Failure,
          Error =>
            (Category => Identity.Errors.Success,
             Retry => Identity.Errors.Do_Not_Retry,
             Cause => Identity.Errors.Caller_Input,
             Operation_Set => False,
             Correlation_Set => False))));

   function Begin_Transaction
     (State : Identity.Adapters.Repositories.Context_State;
      Mode  : Identity.Adapters.Repositories.Transaction_Mode)
      return Transaction_Result
   is
      pragma Unreferenced (Mode);
   begin
      case State is
         when Identity.Adapters.Repositories.Opened =>
            return Success (Identity.Adapters.Repositories.Transaction_Active);
         when Identity.Adapters.Repositories.Transaction_Active =>
            return Failure
              (State,
               Identity.Adapters.Repositories.Failures.Transaction_Already_Active);
         when Identity.Adapters.Repositories.Committed
            | Identity.Adapters.Repositories.Rolled_Back
            | Identity.Adapters.Repositories.Closed =>
            return Failure
              (State,
               Identity.Adapters.Repositories.Failures.Already_Finalized);
         when Identity.Adapters.Repositories.Faulted =>
            return Failure
              (State,
               Identity.Adapters.Repositories.Failures.Backend_Unavailable);
      end case;
   end Begin_Transaction;

   function Commit
     (State : Identity.Adapters.Repositories.Context_State)
      return Transaction_Result is
   begin
      case State is
         when Identity.Adapters.Repositories.Transaction_Active =>
            return Success (Identity.Adapters.Repositories.Committed);
         when Identity.Adapters.Repositories.Opened =>
            return Failure
              (State,
               Identity.Adapters.Repositories.Failures.Transaction_Not_Active);
         when Identity.Adapters.Repositories.Committed
            | Identity.Adapters.Repositories.Rolled_Back
            | Identity.Adapters.Repositories.Closed =>
            return Failure
              (State,
               Identity.Adapters.Repositories.Failures.Already_Finalized);
         when Identity.Adapters.Repositories.Faulted =>
            return Failure
              (State,
               Identity.Adapters.Repositories.Failures.Commit_Failed);
      end case;
   end Commit;

   function Rollback
     (State : Identity.Adapters.Repositories.Context_State)
      return Transaction_Result is
   begin
      case State is
         when Identity.Adapters.Repositories.Transaction_Active =>
            return Success (Identity.Adapters.Repositories.Rolled_Back);
         when Identity.Adapters.Repositories.Opened =>
            return Success (Identity.Adapters.Repositories.Closed);
         when Identity.Adapters.Repositories.Committed
            | Identity.Adapters.Repositories.Rolled_Back
            | Identity.Adapters.Repositories.Closed =>
            return Failure
              (State,
               Identity.Adapters.Repositories.Failures.Already_Finalized);
         when Identity.Adapters.Repositories.Faulted =>
            return Failure
              (State,
               Identity.Adapters.Repositories.Failures.Rollback_Failed);
      end case;
   end Rollback;

   function Close
     (State : Identity.Adapters.Repositories.Context_State)
      return Transaction_Result is
   begin
      case State is
         when Identity.Adapters.Repositories.Opened =>
            return Success (Identity.Adapters.Repositories.Closed);
         when Identity.Adapters.Repositories.Transaction_Active =>
            return Success (Identity.Adapters.Repositories.Rolled_Back);
         when Identity.Adapters.Repositories.Committed
            | Identity.Adapters.Repositories.Rolled_Back
            | Identity.Adapters.Repositories.Closed =>
            return Success (Identity.Adapters.Repositories.Closed);
         when Identity.Adapters.Repositories.Faulted =>
            return Success (Identity.Adapters.Repositories.Closed);
      end case;
   end Close;
end Identity.Adapters.Repositories.Transactions;
