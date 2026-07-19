with Identity.Adapters.Repositories.Stores;
with Identity.Principals.Definitions;

package Identity.Operations.Principals.Create is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Principal  : Identity.Principals.Definitions.Principal_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Principals.Create;
