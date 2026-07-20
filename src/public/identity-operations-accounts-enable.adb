with Identity.Accounts.Definitions;
with Identity.Accounts.States;
with Identity.Events.Envelopes;
with Identity.Events.Types;
with Identity.Identifiers;
with Identity.Identifiers.Operations;
with Identity.Identifiers.Registry;
with Identity.Operations.Audit;
with Identity.Text.Bounded;
with Identity.Versions;

package body Identity.Operations.Accounts.Enable is
   use type Identity.Accounts.States.Administrative_State;
   use type Identity.Versions.Entity_Version;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Enable_Request)
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
        or else Request.Transition.New_State /= Identity.Accounts.States.Enabled
      then
         return Identity.Adapters.Repositories.Stores.State_Conflict;
      end if;

      if not Identity.Accounts.States.Can_Apply
        (Current.State, Identity.Accounts.States.Enable_Administrative)
      then
         return Identity.Adapters.Repositories.Stores.State_Conflict;
      end if;

      Current.State := Identity.Accounts.States.Apply
        (Current.State, Identity.Accounts.States.Enable_Administrative);
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
             Reason => Identity.Identifiers.Registry.From_String ("identity.account.enable"),
             Operation => Identity.Identifiers.Operations.Operation
               (Identity.Identifiers.From_String ("80000000-0000-0000-0000-00000000ae01")),
             Correlation => Identity.Identifiers.Operations.Correlation
               (Identity.Identifiers.From_String ("90000000-0000-0000-0000-00000000ae01")),
             Requested_At => 0,
             Expected_Version => Current.Version,
             Previous_State => Current.State.Administrative,
             New_State => Identity.Accounts.States.Enabled,
             Mandatory_Audit => True)));
   end Execute;
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Enable_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve first: refusing here leaves the store untouched, whereas
      --  discovering a full event log afterwards would leave the account in a
      --  new administrative state that nobody can account for.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Adapters.Repositories.Stores.Capacity_Conflict;
      end if;

      Status := Execute (Repository, Request);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Account_Enabled,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Request.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Request.Account)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful transition.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Emitted;
         end if;
      end;

      return Status;
   end Execute;
end Identity.Operations.Accounts.Enable;
