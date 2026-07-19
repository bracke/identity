with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Projections.Sessions;

package Identity.Operations.Sessions.Enumerate is
   function Execute
     (Repository : Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Projections.Sessions.Session_Summary_List;
end Identity.Operations.Sessions.Enumerate;
