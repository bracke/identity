with Identity.Adapters.Repositories.Stores;
with Identity.Operations.Factors.Generate_Recovery_Codes;
with Identity.Recovery_Codes.Sets;

package Identity.Operations.Factors.Regenerate_Recovery_Codes is
   subtype Regenerate_Request is Identity.Operations.Factors.Generate_Recovery_Codes.Generate_Request;

   type Staged_Regenerate_Request is record
      Request                 : Regenerate_Request;
      Expected_Affected_Count : Natural;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Codes      : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Regenerate_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Regenerate_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Factors.Regenerate_Recovery_Codes;
