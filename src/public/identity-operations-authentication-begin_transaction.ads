with Identity.Adapters.Repositories.Stores;
with Identity.Authentication.Transactions;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Times;

package Identity.Operations.Authentication.Begin_Transaction is

   --  Audited start: a transaction nobody can trace back to a request is a
   --  gap in the sign-in trail, so the record accompanies the transition.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction : Identity.Authentication.Transactions.Authentication_Transaction_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;
end Identity.Operations.Authentication.Begin_Transaction;
