package body Identity.Operations.Sessions.Enumerate is
   function Execute
     (Repository : Identity.Adapters.Repositories.Memory.Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Projections.Sessions.Session_Summary_List is
   begin
      return Identity.Adapters.Repositories.Memory.Enumerate_Principal_Sessions
        (Repository, Principal);
   end Execute;
end Identity.Operations.Sessions.Enumerate;
