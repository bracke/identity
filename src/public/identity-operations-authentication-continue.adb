package body Identity.Operations.Authentication.Continue is
   function Complete_Challenge
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Challenge  : Identity.Identifiers.Entities.Challenge_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Now        : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Complete_Challenge
        (Repository, Challenge, Principal, Now);
   end Complete_Challenge;

   function Complete_Challenge
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Challenge_Completion_Request)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Complete_Challenge
        (Repository,
         Request.Challenge,
         Request.Principal,
         Request.Now,
         Request.Expected_Challenge_Version,
         Request.Expected_Transaction_Version);
   end Complete_Challenge;

   function Satisfy
     (Repository  : in out Identity.Adapters.Repositories.Memory.Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Satisfy_Authentication_Transaction
        (Repository, Transaction, Principal, Now);
   end Satisfy;

   function Satisfy
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Satisfaction_Request)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Satisfy_Authentication_Transaction
        (Repository,
         Request.Transaction,
         Request.Principal,
         Request.Now,
         Request.Expected_Version);
   end Satisfy;
end Identity.Operations.Authentication.Continue;
