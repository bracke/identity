with Identity.Adapters.Repositories.Capabilities;
with Identity.Adapters.Repositories.Failures;

package Identity.Adapters.Repositories.Contexts is
   pragma Pure;

   type Repository_Context is record
      State        : Identity.Adapters.Repositories.Context_State :=
        Identity.Adapters.Repositories.Opened;
      Mode         : Identity.Adapters.Repositories.Transaction_Mode :=
        Identity.Adapters.Repositories.Read_Only;
      Capabilities : Identity.Adapters.Repositories.Capabilities.Repository_Capabilities;
      Failure      : Identity.Adapters.Repositories.Failures.Repository_Failure;
   end record;

   function Opened
     (Capabilities : Identity.Adapters.Repositories.Capabilities.Repository_Capabilities)
      return Repository_Context;

   function In_Transaction (Context : Repository_Context) return Boolean is
     (Context.State = Identity.Adapters.Repositories.Transaction_Active);
end Identity.Adapters.Repositories.Contexts;
