with Identity.Adapters.Repositories.Memory;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Secrets.Bytes;
with Identity.Times;
with Identity.Tokens.Definitions;
with Identity.Versions;

package Identity.Operations.Tokens.Issue is
   type Issue_Request is record
      Id              : Identity.Identifiers.Entities.Token_Id;
      Purpose         : Identity.Identifiers.Registry.Registry_Id;
      Principal       : Identity.Identifiers.Entities.Principal_Id;
      Verifier_Domain : Identity.Identifiers.Registry.Registry_Id;
      Secret          : Identity.Secrets.Bytes.Secret_Bytes;
      Issued_At       : Identity.Times.Instant := 0;
      Expires_At      : Identity.Times.Expiration;
      Attempts        : Identity.Versions.Attempt_Count := 0;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Token      : Identity.Tokens.Definitions.Action_Token_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Issue_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status;
end Identity.Operations.Tokens.Issue;
