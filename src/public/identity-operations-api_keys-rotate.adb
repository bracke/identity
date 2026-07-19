with Identity.Credentials.States;
with Identity.Crypto.Domains;
with Identity.Crypto.Secret_Verifiers;
with Identity.API_Keys.Policies;

package body Identity.Operations.API_Keys.Rotate is
   use type Identity.API_Keys.Policies.Issue_Lifetime_Status;

   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Memory.Store;
      Predecessor : Identity.Identifiers.Entities.Credential_Id;
      Successor   : Identity.API_Keys.Credentials.API_Key_Credential_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Rotate_API_Key
        (Repository, Predecessor, Successor);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Rotate_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      if Identity.API_Keys.Policies.Evaluate_Issue_Lifetime
        (Identity.API_Keys.Policies.API_Key_Policy'
           (Maximum_Active_Keys_Per_Principal => 16,
            Maximum_Overlap => 86_400,
            Expiration_Required => True),
         Request.Created_At,
         Request.Expires_At)
        /= Identity.API_Keys.Policies.Issue_Lifetime_Allowed
      then
         return Identity.Adapters.Repositories.Memory.State_Conflict;
      end if;

      return Identity.Adapters.Repositories.Memory.Rotate_API_Key
        (Repository,
         Request.Predecessor,
         (Id              => Request.Id,
          Principal       => Request.Principal,
          Public_Key_Id   => Request.Public_Key_Id,
          Credential_Class_Id => Request.Credential_Class_Id,
          Secret_Verifier => Identity.Crypto.Secret_Verifiers.Derive_Text
            (Identity.Crypto.Domains.API_Key, Request.Secret),
          State           => Identity.Credentials.States.Active,
          Created_At      => Request.Created_At,
          Expires_At      => Request.Expires_At,
          Last_Used_At    => (Present => False, Time_Point => 0),
          Rotation_Generation => Request.Rotation_Generation,
          Version         => 0));
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Rotate_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      if Identity.API_Keys.Policies.Evaluate_Issue_Lifetime
        (Identity.API_Keys.Policies.API_Key_Policy'
           (Maximum_Active_Keys_Per_Principal => 16,
            Maximum_Overlap => 86_400,
            Expiration_Required => True),
         Request.Request.Created_At,
         Request.Request.Expires_At)
        /= Identity.API_Keys.Policies.Issue_Lifetime_Allowed
      then
         return Identity.Adapters.Repositories.Memory.State_Conflict;
      end if;

      return Identity.Adapters.Repositories.Memory.Rotate_API_Key
        (Repository,
         Request.Request.Predecessor,
         Request.Expected_Predecessor_Version,
         (Id              => Request.Request.Id,
          Principal       => Request.Request.Principal,
          Public_Key_Id   => Request.Request.Public_Key_Id,
          Credential_Class_Id => Request.Request.Credential_Class_Id,
          Secret_Verifier => Identity.Crypto.Secret_Verifiers.Derive_Text
            (Identity.Crypto.Domains.API_Key, Request.Request.Secret),
          State           => Identity.Credentials.States.Active,
          Created_At      => Request.Request.Created_At,
          Expires_At      => Request.Request.Expires_At,
          Last_Used_At    => (Present => False, Time_Point => 0),
          Rotation_Generation => Request.Request.Rotation_Generation,
          Version         => 0));
   end Execute;
end Identity.Operations.API_Keys.Rotate;
