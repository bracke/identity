package body Identity.Adapters.Repositories.Factories is
   function Open
     (Factory : Repository_Factory)
      return Identity.Adapters.Repositories.Contexts.Repository_Context is
     (Identity.Adapters.Repositories.Contexts.Opened (Factory.Capabilities));
end Identity.Adapters.Repositories.Factories;
