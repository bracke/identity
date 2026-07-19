with Identity.Adapters.Repositories.Memory;
with Identity.Assurance.Attributes;
with Identity.Assurance.Levels;
with Identity.Authentication.Transactions;
with Identity.Identifiers.Entities;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.Sessions.Upgrade_Assurance is
   type Staged_Upgrade_Request is record
      Session                      : Identity.Identifiers.Entities.Session_Id;
      Transaction                  : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal                    : Identity.Identifiers.Entities.Principal_Id;
      Now                          : Identity.Times.Instant;
      Assurance                    : Identity.Assurance.Levels.Assurance_Level;
      Attributes                   : Identity.Assurance.Attributes.Assurance_Attributes;
      Expected_Session_Version     : Identity.Versions.Entity_Version;
      Expected_Transaction_Version : Identity.Versions.Entity_Version;
   end record;

   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Memory.Store;
      Session     : Identity.Identifiers.Entities.Session_Id;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant;
      Assurance   : Identity.Assurance.Levels.Assurance_Level;
      Attributes  : Identity.Assurance.Attributes.Assurance_Attributes)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Upgrade_Request)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;
end Identity.Operations.Sessions.Upgrade_Assurance;
