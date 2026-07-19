with Identity.Adapters.Repositories.Capabilities;
with Identity.Adapters.Repositories.Contexts;

package Identity.Adapters.Repositories.Factories is
   pragma Pure;

   type Repository_Factory is record
      Capabilities : Identity.Adapters.Repositories.Capabilities.Repository_Capabilities;
   end record;

   function Open
     (Factory : Repository_Factory)
      return Identity.Adapters.Repositories.Contexts.Repository_Context;
end Identity.Adapters.Repositories.Factories;
