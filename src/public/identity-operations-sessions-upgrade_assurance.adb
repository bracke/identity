package body Identity.Operations.Sessions.Upgrade_Assurance is
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Memory.Store;
      Session     : Identity.Identifiers.Entities.Session_Id;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant;
      Assurance   : Identity.Assurance.Levels.Assurance_Level;
      Attributes  : Identity.Assurance.Attributes.Assurance_Attributes)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Upgrade_Session_Assurance
        (Repository, Session, Transaction, Principal, Now, Assurance, Attributes);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Upgrade_Request)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Upgrade_Session_Assurance
        (Repository,
         Request.Session,
         Request.Transaction,
         Request.Principal,
         Request.Now,
         Request.Assurance,
         Request.Attributes,
         Request.Expected_Session_Version,
         Request.Expected_Transaction_Version);
   end Execute;
end Identity.Operations.Sessions.Upgrade_Assurance;
