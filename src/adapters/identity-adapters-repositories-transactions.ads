with Identity.Adapters.Repositories.Failures;

package Identity.Adapters.Repositories.Transactions is
   pragma Pure;

   type Transaction_Result is record
      State   : Identity.Adapters.Repositories.Context_State :=
        Identity.Adapters.Repositories.Opened;
      Failure : Identity.Adapters.Repositories.Failures.Repository_Failure;
   end record;

   function Succeeded (Result : Transaction_Result) return Boolean is
     (not Identity.Adapters.Repositories.Failures.Is_Failure (Result.Failure));

   function Failed (Result : Transaction_Result) return Boolean is
     (Identity.Adapters.Repositories.Failures.Is_Failure (Result.Failure));

   function Active (Result : Transaction_Result) return Boolean is
     (Succeeded (Result)
      and then Identity.Adapters.Repositories.In_Transaction (Result.State));

   function Committed (Result : Transaction_Result) return Boolean is
     (Succeeded (Result)
      and then Identity.Adapters.Repositories.Is_Committed (Result.State));

   function Rolled_Back (Result : Transaction_Result) return Boolean is
     (Succeeded (Result)
      and then Identity.Adapters.Repositories.Is_Rolled_Back (Result.State));

   function Begin_Transaction
     (State : Identity.Adapters.Repositories.Context_State;
      Mode  : Identity.Adapters.Repositories.Transaction_Mode)
      return Transaction_Result;

   function Commit
     (State : Identity.Adapters.Repositories.Context_State)
      return Transaction_Result;

   function Rollback
     (State : Identity.Adapters.Repositories.Context_State)
      return Transaction_Result;

   function Close
     (State : Identity.Adapters.Repositories.Context_State)
      return Transaction_Result;
end Identity.Adapters.Repositories.Transactions;
