package body Identity.Operations.Factors.Regenerate_Recovery_Codes is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Codes      : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Regenerate_Recovery_Code_Set
        (Repository, Codes);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Regenerate_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Regenerate_Recovery_Code_Set
        (Repository,
         Identity.Operations.Factors.Generate_Recovery_Codes.To_Record (Request));
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Regenerate_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Regenerate_Recovery_Code_Set
        (Repository,
         Identity.Operations.Factors.Generate_Recovery_Codes.To_Record (Request.Request),
         Request.Expected_Affected_Count);
   end Execute;
end Identity.Operations.Factors.Regenerate_Recovery_Codes;
