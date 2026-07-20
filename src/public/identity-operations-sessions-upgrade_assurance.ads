with Identity.Adapters.Repositories.Stores;
with Identity.Assurance.Attributes;
with Identity.Assurance.Levels;
with Identity.Authentication.Transactions;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
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

   --  Audited upgrade: a session that gains assurance without a record leaves
   --  no answer to "what raised this session's standing, and when?".
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Upgrade_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;

   --  Audited upgrade taking the raised standing directly, for callers that
   --  hold no expected versions to stage.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Session     : Identity.Identifiers.Entities.Session_Id;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant;
      Assurance   : Identity.Assurance.Levels.Assurance_Level;
      Attributes  : Identity.Assurance.Attributes.Assurance_Attributes;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;
end Identity.Operations.Sessions.Upgrade_Assurance;
