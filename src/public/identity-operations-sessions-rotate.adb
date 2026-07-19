with Identity.Crypto.Domains;
with Identity.Crypto.Secret_Verifiers;

package body Identity.Operations.Sessions.Rotate is
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Predecessor : Identity.Identifiers.Entities.Session_Id;
      Successor   : Identity.Sessions.Definitions.Session_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Rotate_Session
        (Repository, Predecessor, Successor);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Rotate_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Rotate_Session
        (Repository,
         Request.Predecessor,
         (Id              => Request.Id,
          Family          => Request.Family,
          Principal       => Request.Principal,
          Credential      => Request.Credential,
          External_Provider => Request.External_Provider,
          Public_Reference => Request.Public_Reference,
          Secret_Verifier => Identity.Crypto.Secret_Verifiers.Derive_Text
            (Identity.Crypto.Domains.Session_Token, Request.Secret),
          Assurance       => Request.Assurance,
          Attributes      => Request.Attributes,
          Created_At      => Request.Created_At,
          Original_Authenticated_At => Request.Original_Authenticated_At,
          Primary_Authenticated_At => Request.Primary_Authenticated_At,
          MFA_Completed_At => Request.MFA_Completed_At,
          Step_Up_At      => Request.Step_Up_At,
          Last_Seen_At    => Request.Last_Seen_At,
          Idle_Expires_At => Request.Idle_Expires_At,
          Absolute_Expires_At => Request.Absolute_Expires_At,
          Remembered      => Request.Remembered,
          Generation      => Request.Generation,
          State           => Identity.Sessions.Definitions.Active,
          Version         => 0));
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Rotate_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Rotate_Session
        (Repository,
         Request.Request.Predecessor,
         Request.Expected_Predecessor_Version,
         (Id              => Request.Request.Id,
          Family          => Request.Request.Family,
          Principal       => Request.Request.Principal,
          Credential      => Request.Request.Credential,
          External_Provider => Request.Request.External_Provider,
          Public_Reference => Request.Request.Public_Reference,
          Secret_Verifier => Identity.Crypto.Secret_Verifiers.Derive_Text
            (Identity.Crypto.Domains.Session_Token, Request.Request.Secret),
          Assurance       => Request.Request.Assurance,
          Attributes      => Request.Request.Attributes,
          Created_At      => Request.Request.Created_At,
          Original_Authenticated_At =>
            Request.Request.Original_Authenticated_At,
          Primary_Authenticated_At =>
            Request.Request.Primary_Authenticated_At,
          MFA_Completed_At => Request.Request.MFA_Completed_At,
          Step_Up_At      => Request.Request.Step_Up_At,
          Last_Seen_At    => Request.Request.Last_Seen_At,
          Idle_Expires_At => Request.Request.Idle_Expires_At,
          Absolute_Expires_At => Request.Request.Absolute_Expires_At,
          Remembered      => Request.Request.Remembered,
          Generation      => Request.Request.Generation,
          State           => Identity.Sessions.Definitions.Active,
          Version         => 0));
   end Execute;
end Identity.Operations.Sessions.Rotate;
