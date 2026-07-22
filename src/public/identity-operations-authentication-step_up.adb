with Identity.Assurance.Evaluation;
with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Sessions.Definitions;
with Identity.Text.Bounded;

package body Identity.Operations.Authentication.Step_Up is
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Session     : Identity.Identifiers.Entities.Session_Id;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant;
      Assurance   : Identity.Assurance.Levels.Assurance_Level;
      Attributes  : Identity.Assurance.Attributes.Assurance_Attributes)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Upgrade_Session_Assurance
        (Repository, Session, Transaction, Principal, Now, Assurance, Attributes);
   end Execute;

   --  A transaction verdict is not a store command status: an unknown session
   --  or wrongly-staged transaction is a conflict, not a plain rejection.

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Session     : Identity.Identifiers.Entities.Session_Id;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant;
      Assurance   : Identity.Assurance.Levels.Assurance_Level;
      Attributes  : Identity.Assurance.Attributes.Assurance_Attributes;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Authentication.Transactions
        .Authentication_Transaction_Status;
   begin
      --  Reserve first: refusing here leaves the session at its old standing
      --  rather than raising it with nothing to show for the raise.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Authentication.Transactions.Capacity_Conflict;
      end if;

      Status := Execute
        (Repository, Session, Transaction, Principal, Now, Assurance,
         Attributes);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Session_Assurance_Upgraded,
              Subject     => Identity.Operations.Audit.Subject_Of (Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Session)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful transition.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Identity.Authentication.Transactions.Capacity_Conflict;
         end if;
      end;

      return Status;
   end Execute;

   function Execute
     (Repository        : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Binding           : Identity.Multi_Factor.Step_Up.Step_Up_Binding;
      Transaction       : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Requested_Profile : Identity.Identifiers.Registry.Registry_Id;
      Now               : Identity.Times.Instant;
      Assurance         : Identity.Assurance.Levels.Assurance_Level;
      Attributes        : Identity.Assurance.Attributes.Assurance_Attributes;
      Context           : Identity.Operations.Contexts.Operation_Context;
      Event             : Identity.Identifiers.Entities.Event_Id;
      Recorded_At       : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
      Found       : Boolean;
      Session_Rec : Identity.Sessions.Definitions.Session_Record;
   begin
      Identity.Adapters.Repositories.Stores.Find_Session
        (Repository, Binding.Session, Found, Session_Rec);

      --  A rotated, replaced or wrong session no longer matches the family and
      --  generation the caller bound the step-up to.
      if not Found
        or else not Identity.Multi_Factor.Step_Up.Matches (Binding, Session_Rec)
      then
         return Identity.Authentication.Transactions.State_Conflict;
      end if;

      --  If the session already satisfies the requested profile there is
      --  nothing to raise: report success without a spurious upgrade event.
      if Identity.Assurance.Evaluation.Evaluation_Satisfied
           (Identity.Assurance.Evaluation.Evaluate
              (Requested_Profile, Session_Rec.Attributes))
      then
         return Identity.Authentication.Transactions.Applied;
      end if;

      --  A real raise is needed: perform the audited atomic upgrade against the
      --  bound session and principal.
      return Execute
        (Repository, Binding.Session, Transaction, Binding.Principal, Now,
         Assurance, Attributes, Context, Event, Recorded_At);
   end Execute;
end Identity.Operations.Authentication.Step_Up;
