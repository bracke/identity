with Identity.Adapters.Repositories.Stores;
with Identity.Authentication.Challenges;
with Identity.Authentication.Transactions;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.Factors.Issue_Challenge is
   type Staged_Issue_Request is record
      Challenge                    : Identity.Authentication.Challenges.Challenge_Record;
      Expected_Transaction_Version : Identity.Versions.Entity_Version;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Challenge  : Identity.Authentication.Challenges.Challenge_Record)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Issue_Request)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;

   --  Audited form. Emits identity.mfa.challenge.issued for the transition,
   --  and refuses the operation if the store cannot accept that event, so a
   --  challenge is never issued without its audit record.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Issue_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;
end Identity.Operations.Factors.Issue_Challenge;
