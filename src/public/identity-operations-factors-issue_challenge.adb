package body Identity.Operations.Factors.Issue_Challenge is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Challenge  : Identity.Authentication.Challenges.Challenge_Record)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Issue_Challenge (Repository, Challenge);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Issue_Request)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Issue_Challenge
        (Repository, Request.Challenge, Request.Expected_Transaction_Version);
   end Execute;
end Identity.Operations.Factors.Issue_Challenge;
