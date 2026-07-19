with Identity.Adapters.Repositories.Memory;
with Identity.Identifiers.Entities;
with Identity.Projections.Sessions;

package Identity.Operations.Sessions.Enumerate is
   function Execute
     (Repository : Identity.Adapters.Repositories.Memory.Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Projections.Sessions.Session_Summary_List;
end Identity.Operations.Sessions.Enumerate;
