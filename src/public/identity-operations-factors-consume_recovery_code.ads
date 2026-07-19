with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Recovery_Codes.Sets;
with Identity.Secrets.Recovery_Codes;
with Identity.Versions;

package Identity.Operations.Factors.Consume_Recovery_Code is
   subtype Recovery_Code_Consume_Status is Identity.Recovery_Codes.Sets.Recovery_Code_Consume_Status;

   type Consume_Request is record
      Set_Id           : Identity.Identifiers.Entities.Credential_Set_Id;
      Expected_Version : Identity.Versions.Entity_Version;
      Code             : Identity.Secrets.Recovery_Codes.Recovery_Code;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Set_Id     : Identity.Identifiers.Entities.Credential_Set_Id;
      Code       : Identity.Secrets.Recovery_Codes.Recovery_Code)
      return Recovery_Code_Consume_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Consume_Request)
      return Recovery_Code_Consume_Status;
end Identity.Operations.Factors.Consume_Recovery_Code;
