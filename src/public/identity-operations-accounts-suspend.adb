with Identity.Accounts.Definitions;
with Identity.Accounts.States;
with Identity.Events.Envelopes;
with Identity.Identifiers;
with Identity.Identifiers.Operations;
with Identity.Identifiers.Registry;
with Identity.Versions;

package body Identity.Operations.Accounts.Suspend is
   use type Identity.Accounts.States.Administrative_State;
   use type Identity.Versions.Entity_Version;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Suspend_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      Found : Boolean;
      Current : Identity.Accounts.Definitions.Account_Record;
   begin
      Identity.Adapters.Repositories.Stores.Find_Account
        (Repository, Request.Principal, Found, Current);

      if not Found or else Identity.Identifiers.Entities.To_String (Current.Id)
        /= Identity.Identifiers.Entities.To_String (Request.Account)
      then
         return Identity.Adapters.Repositories.Stores.State_Conflict;
      end if;

      if not Identity.Accounts.Administrative.Valid_Transition_Request
        (Request.Transition)
        or else Request.Transition.Expected_Version /= Current.Version
        or else Request.Transition.Previous_State /= Current.State.Administrative
        or else Request.Transition.New_State /= Identity.Accounts.States.Suspended
      then
         return Identity.Adapters.Repositories.Stores.State_Conflict;
      end if;

      if not Identity.Accounts.States.Can_Apply
        (Current.State, Identity.Accounts.States.Suspend_Administrative)
      then
         return Identity.Adapters.Repositories.Stores.State_Conflict;
      end if;

      Current.State := Identity.Accounts.States.Apply
        (Current.State, Identity.Accounts.States.Suspend_Administrative);
      return Identity.Adapters.Repositories.Stores.Update_Account_State
        (Repository, Request.Account, Request.Principal, Current.State);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Account    : Identity.Identifiers.Entities.Account_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      Found : Boolean;
      Current : Identity.Accounts.Definitions.Account_Record;
   begin
      Identity.Adapters.Repositories.Stores.Find_Account
        (Repository, Principal, Found, Current);

      if not Found then
         return Identity.Adapters.Repositories.Stores.State_Conflict;
      end if;

      return Execute
        (Repository,
         (Account => Account,
          Principal => Principal,
          Transition =>
            (Actor => (Kind => Identity.Events.Envelopes.Authenticated_Principal,
                       Principal => (Present => True, Value => Principal)),
             Reason => Identity.Identifiers.Registry.From_String ("identity.account.suspend"),
             Operation => Identity.Identifiers.Operations.Operation
               (Identity.Identifiers.From_String ("80000000-0000-0000-0000-00000000aa01")),
             Correlation => Identity.Identifiers.Operations.Correlation
               (Identity.Identifiers.From_String ("90000000-0000-0000-0000-00000000aa01")),
             Requested_At => 0,
             Expected_Version => Current.Version,
             Previous_State => Current.State.Administrative,
             New_State => Identity.Accounts.States.Suspended,
             Mandatory_Audit => True)));
   end Execute;
end Identity.Operations.Accounts.Suspend;
