package body Identity.Operations.Factors.Consume_Recovery_Code is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Set_Id     : Identity.Identifiers.Entities.Credential_Set_Id;
      Code       : Identity.Secrets.Recovery_Codes.Recovery_Code)
      return Recovery_Code_Consume_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Consume_Recovery_Code (Repository, Set_Id, Code);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Consume_Request)
      return Recovery_Code_Consume_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Consume_Recovery_Code
        (Repository,
         Request.Set_Id,
         Request.Expected_Version,
         Request.Code);
   end Execute;
end Identity.Operations.Factors.Consume_Recovery_Code;
