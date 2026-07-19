with Identity.API_Keys.Credentials;
with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Secrets.API_Keys;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.API_Keys.Rotate is
   type Rotate_Request is record
      Predecessor         : Identity.Identifiers.Entities.Credential_Id;
      Id                  : Identity.Identifiers.Entities.Credential_Id;
      Principal           : Identity.Identifiers.Entities.Principal_Id;
      Public_Key_Id       : Identity.Text.Bounded.Bounded_Text;
      Credential_Class_Id : Identity.Identifiers.Registry.Registry_Id;
      Secret              : Identity.Secrets.API_Keys.API_Key_Secret;
      Created_At          : Identity.Times.Instant := 0;
      Expires_At          : Identity.Times.Expiration;
      Rotation_Generation : Identity.Versions.Rotation_Generation := 0;
   end record;

   type Staged_Rotate_Request is record
      Request                      : Rotate_Request;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
   end record;

   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Predecessor : Identity.Identifiers.Entities.Credential_Id;
      Successor   : Identity.API_Keys.Credentials.API_Key_Credential_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Rotate_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Rotate_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.API_Keys.Rotate;
