with Identity.Adapters.Repositories.Capabilities;

package Identity.Testing.Repositories is
   function Required_Memory_Capabilities
      return Identity.Adapters.Repositories.Capabilities.Repository_Capabilities is
     (Identity.Adapters.Repositories.Capabilities.Full_Memory_Profile);
end Identity.Testing.Repositories;
