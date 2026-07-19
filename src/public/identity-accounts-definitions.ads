with Identity.Accounts.States;
with Identity.Identifiers.Entities;
with Identity.Versions;

package Identity.Accounts.Definitions is
   pragma Pure;

   type Account_Record is record
      Id        : Identity.Identifiers.Entities.Account_Id;
      Principal : Identity.Identifiers.Entities.Principal_Id;
      State     : Identity.Accounts.States.Account_State_View;
      Version   : Identity.Versions.Entity_Version := 0;
   end record;
end Identity.Accounts.Definitions;
