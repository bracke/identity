with Identity.Adapters.Repositories.Memory;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
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
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Purpose    : Identity.Identifiers.Registry.Registry_Id;
      Secret     : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now        : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Consume_Request)
      return Identity.Tokens.Verification.Token_Verification_Outcome;
end Identity.Operations.Tokens.Consume;
