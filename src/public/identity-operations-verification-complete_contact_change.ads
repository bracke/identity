with Identity.Adapters.Repositories.Memory;
with Identity.Identifiers.Entities;
with Identity.Secrets.Tokens;
with Identity.Times;
with Identity.Tokens.Verification;
with Identity.Versions;

package Identity.Operations.Verification.Complete_Contact_Change is
   type Staged_Completion_Request is record
      Token                        : Identity.Identifiers.Entities.Token_Id;
      Expected_Token_Version       : Identity.Versions.Entity_Version;
      Expected_Change_Version      : Identity.Versions.Entity_Version;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Expected_Successor_Version   : Identity.Versions.Entity_Version;
      Secret                       : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now                          : Identity.Times.Instant;
      Predecessor                  : Identity.Identifiers.Entities.Contact_Binding_Id;
      Successor                    : Identity.Identifiers.Entities.Contact_Binding_Id;
   end record;

   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Memory.Store;
      Token       : Identity.Identifiers.Entities.Token_Id;
      Secret      : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now         : Identity.Times.Instant;
      Predecessor : Identity.Identifiers.Entities.Contact_Binding_Id;
      Successor   : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Completion_Request)
      return Identity.Tokens.Verification.Token_Verification_Outcome;
end Identity.Operations.Verification.Complete_Contact_Change;
