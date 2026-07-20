with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Secrets.Passwords;
with Identity.Secrets.Tokens;
with Identity.Times;
with Identity.Tokens.Verification;
with Identity.Versions;

package Identity.Operations.Passwords.Complete_Reset is
   type Reset_Completion_Request is record
      Token                        : Identity.Identifiers.Entities.Token_Id;
      Principal                    : Identity.Identifiers.Entities.Principal_Id;
      Secret                       : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now                          : Identity.Times.Instant;
      New_Credential               : Identity.Identifiers.Entities.Credential_Id;
      Password                     : Identity.Secrets.Passwords.New_Password;
      Expected_Token_Version       : Identity.Versions.Entity_Version;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
   end record;

   function Execute
     (Repository     : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Token          : Identity.Identifiers.Entities.Token_Id;
      Principal      : Identity.Identifiers.Entities.Principal_Id;
      Secret         : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now            : Identity.Times.Instant;
      New_Credential : Identity.Identifiers.Entities.Credential_Id;
      Password       : Identity.Secrets.Passwords.New_Password)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Reset_Completion_Request)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   --  Audited form. Emits identity.password.reset.completed for the
   --  transition, and refuses the operation if the store cannot accept that
   --  event, so a reset is never completed without its audit record. An
   --  invalid token is audited as a rejection.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Reset_Completion_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   --  Audited form taking the completion directly. An invalid token is
   --  audited as a rejection.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Token          : Identity.Identifiers.Entities.Token_Id;
      Principal      : Identity.Identifiers.Entities.Principal_Id;
      Secret         : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now            : Identity.Times.Instant;
      New_Credential : Identity.Identifiers.Entities.Credential_Id;
      Password       : Identity.Secrets.Passwords.New_Password;
      Context        : Identity.Operations.Contexts.Operation_Context;
      Event          : Identity.Identifiers.Entities.Event_Id;
      Recorded_At    : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome;
end Identity.Operations.Passwords.Complete_Reset;
