with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Operations.Contexts;
with Identity.Secrets.Tokens;
with Identity.Times;
with Identity.Tokens.Verification;
with Identity.Versions;

package Identity.Operations.Tokens.Consume is
   type Consume_Request is record
      Token            : Identity.Identifiers.Entities.Token_Id;
      Expected_Version : Identity.Versions.Entity_Version;
      Purpose          : Identity.Identifiers.Registry.Registry_Id;
      Secret           : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now              : Identity.Times.Instant;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Purpose    : Identity.Identifiers.Registry.Registry_Id;
      Secret     : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now        : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Consume_Request)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   --  Audited form. Emits identity.token.consumed for the attempt -- rejected
   --  presentations included, since a stream of them is what an attack looks
   --  like -- and refuses the operation if the store cannot accept that event.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Consume_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   --  Audited form taking the presentation directly. Rejected attempts are
   --  recorded too, since a stream of them is what an attack looks like.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Token       : Identity.Identifiers.Entities.Token_Id;
      Purpose     : Identity.Identifiers.Registry.Registry_Id;
      Secret      : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now         : Identity.Times.Instant;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome;
end Identity.Operations.Tokens.Consume;
