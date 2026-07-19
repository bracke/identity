with Identity.Adapters.Repositories.Memory;
with Identity.Principals.Definitions;

package Identity.Operations.Principals.Create is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Principal  : Identity.Principals.Definitions.Principal_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status;
end Identity.Operations.Principals.Create;
