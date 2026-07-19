with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Authentication.Transactions;
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
end Identity.Operations.Authentication.Continue;
