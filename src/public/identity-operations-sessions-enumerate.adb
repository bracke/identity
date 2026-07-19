package body Identity.Operations.Sessions.Enumerate is
   function Execute
     (Repository : Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Projections.Sessions.Session_Summary_List is
   begin
      return Identity.Adapters.Repositories.Stores.Enumerate_Principal_Sessions
        (Repository, Principal);
   end Execute;
end Identity.Operations.Sessions.Enumerate;
