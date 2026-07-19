with Identity.Crypto.Domains;
with Identity.Crypto.Secret_Verifiers;

package body Identity.Operations.Sessions.Create is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Session    : Identity.Sessions.Definitions.Session_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Create_Session (Repository, Session);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Create_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Create_Session
        (Repository,
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
end Identity.Operations.Sessions.Create;
