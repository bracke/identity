with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Secrets.Passwords;

package Identity.Operations.Passwords.Enroll is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Password   : Identity.Secrets.Passwords.New_Password)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Passwords.Enroll;
