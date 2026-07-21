with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Authentication.Transactions;
with Identity.Operations.Contexts;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.Authentication.Continue is
   type Staged_Challenge_Completion_Request is record
      Challenge                    : Identity.Identifiers.Entities.Challenge_Id;
      Principal                    : Identity.Identifiers.Entities.Principal_Id;
      Now                          : Identity.Times.Instant;
      Expected_Challenge_Version   : Identity.Versions.Entity_Version;
      Expected_Transaction_Version : Identity.Versions.Entity_Version;
   end record;

   type Staged_Satisfaction_Request is record
      Transaction      : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Now              : Identity.Times.Instant;
      Expected_Version : Identity.Versions.Entity_Version;
   end record;

   function Complete_Challenge
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Challenge  : Identity.Identifiers.Entities.Challenge_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Now        : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;

   function Complete_Challenge
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Challenge_Completion_Request)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;

   --  Audited form. Emits identity.mfa.challenge.completed for the
   --  transition, and refuses the operation if the store cannot accept that
   --  event, so a challenge is never completed without its audit record.
   function Complete_Challenge
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Challenge_Completion_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;

   function Satisfy
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;

   function Satisfy
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Satisfaction_Request)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;

   --  Resolve an in-progress transaction unsuccessfully -- rejected by policy
   --  or a failed factor (Reject_Transaction), or cancelled by the caller
   --  (Cancel_Transaction). Before this, Rejected and Cancelled were dead
   --  states with no path. Audited under identity.authentication.rejected.
   function Resolve
     (Repository       : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Transaction      : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Action           : Identity.Authentication.Transactions.Authentication_Transaction_Action;
      Now              : Identity.Times.Instant;
      Expected_Version : Identity.Versions.Entity_Version;
      Context          : Identity.Operations.Contexts.Operation_Context;
      Event            : Identity.Identifiers.Entities.Event_Id;
      Recorded_At      : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;
end Identity.Operations.Authentication.Continue;
