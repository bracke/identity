with Identity.Accounts.Definitions;
with Identity.Accounts.States;

package body Identity.Operations.Accounts.Require_MFA is
   use type Identity.Versions.Entity_Version;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Requirement_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status
   is
      Found : Boolean;
      Current : Identity.Accounts.Definitions.Account_Record;
   begin
      Identity.Adapters.Repositories.Memory.Find_Account
        (Repository, Request.Principal, Found, Current);

      if not Found or else Identity.Identifiers.Entities.To_String (Current.Id)
        /= Identity.Identifiers.Entities.To_String (Request.Account)
        or else Current.Version /= Request.Expected_Version
      then
         return Identity.Adapters.Repositories.Memory.State_Conflict;
      end if;

      if not Identity.Accounts.States.Can_Apply
        (Current.State, Identity.Accounts.States.Require_MFA_Enrollment)
      then
         return Identity.Adapters.Repositories.Memory.State_Conflict;
      end if;

      Current.State := Identity.Accounts.States.Apply
        (Current.State, Identity.Accounts.States.Require_MFA_Enrollment);
      return Identity.Adapters.Repositories.Memory.Update_Account_State
        (Repository, Request.Account, Request.Principal, Current.State);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Account    : Identity.Identifiers.Entities.Account_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Adapters.Repositories.Memory.Command_Status
   is
      Found : Boolean;
      Current : Identity.Accounts.Definitions.Account_Record;
   begin
      Identity.Adapters.Repositories.Memory.Find_Account
        (Repository, Principal, Found, Current);

      if not Found then
         return Identity.Adapters.Repositories.Memory.State_Conflict;
      end if;

      return Execute
        (Repository,
         (Account => Account,
          Principal => Principal,
          Expected_Version => Current.Version));
   end Execute;
end Identity.Operations.Accounts.Require_MFA;
