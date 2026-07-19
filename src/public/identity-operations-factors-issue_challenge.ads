with Identity.Adapters.Repositories.Stores;
with Identity.Authentication.Challenges;
with Identity.Authentication.Transactions;
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
end Identity.Operations.Factors.Issue_Challenge;
