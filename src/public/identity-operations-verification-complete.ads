with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Secrets.Tokens;
with Identity.Times;
with Identity.Tokens.Verification;
with Identity.Versions;

package Identity.Operations.Verification.Complete is
   type Staged_Completion_Request is record
      Token                    : Identity.Identifiers.Entities.Token_Id;
      Expected_Token_Version   : Identity.Versions.Entity_Version;
      Expected_Contact_Version : Identity.Versions.Entity_Version;
      Secret                   : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now                      : Identity.Times.Instant;
      Contact                  : Identity.Identifiers.Entities.Contact_Binding_Id;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Secret     : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now        : Identity.Times.Instant;
      Contact    : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Completion_Request)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   --  Audited form. Emits identity.contact.verified for the transition, and
   --  refuses the operation if the store cannot accept that event, so a
   --  contact is never marked verified without its audit record.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Completion_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   --  Audited form taking the presentation directly, for callers that hold
   --  no expected versions to stage.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Token       : Identity.Identifiers.Entities.Token_Id;
      Secret      : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now         : Identity.Times.Instant;
      Contact     : Identity.Identifiers.Entities.Contact_Binding_Id;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome;
end Identity.Operations.Verification.Complete;
