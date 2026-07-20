with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;

package body Identity.Operations.Sessions.Upgrade_Assurance is
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

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Upgrade_Request)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Upgrade_Session_Assurance
        (Repository,
         Request.Session,
         Request.Transaction,
         Request.Principal,
         Request.Now,
         Request.Assurance,
         Request.Attributes,
         Request.Expected_Session_Version,
         Request.Expected_Transaction_Version);
   end Execute;

   --  A transaction verdict is not a store command status: an unknown session
   --  or a version that moved under the request is a conflict, not a plain
   --  rejection.

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Upgrade_Request;
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

      Status := Execute (Repository, Request);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Session_Assurance_Upgraded,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Request.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Request.Session)),
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
end Identity.Operations.Sessions.Upgrade_Assurance;
