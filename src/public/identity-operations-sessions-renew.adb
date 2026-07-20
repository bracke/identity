with Identity.Events.Types;
with Identity.Operations.Audit;

package body Identity.Operations.Sessions.Renew is
   function Execute
     (Repository       : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Public_Reference : Identity.Text.Bounded.Bounded_Text;
      Secret           : Identity.Secrets.Sessions.Session_Secret;
      Now              : Identity.Times.Instant;
      Idle_Expires_At  : Identity.Times.Expiration)
      return Identity.Sessions.Handles.Session_Handle is
   begin
      return Identity.Adapters.Repositories.Stores.Renew_Session
        (Repository, Public_Reference, Secret, Now, Idle_Expires_At);
   end Execute;

   --  A lookup verdict is not a store command status: a reference that
   --  resolves to nothing usable is a rejection of what was presented, not a
   --  race with stored state.

   function Execute
     (Repository       : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Public_Reference : Identity.Text.Bounded.Bounded_Text;
      Secret           : Identity.Secrets.Sessions.Session_Secret;
      Now              : Identity.Times.Instant;
      Idle_Expires_At  : Identity.Times.Expiration;
      Context          : Identity.Operations.Contexts.Operation_Context;
      Event            : Identity.Identifiers.Entities.Event_Id;
      Recorded_At      : Identity.Times.Instant)
      return Identity.Sessions.Handles.Session_Handle
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Handle : Identity.Sessions.Handles.Session_Handle;
   begin
      --  Reserve first: refusing here leaves the session on its original
      --  idle deadline rather than extending it with nothing to show for it.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return (Status => Identity.Sessions.Handles.Unknown);
      end if;

      Handle := Execute
        (Repository, Public_Reference, Secret, Now, Idle_Expires_At);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Session_Renewed,
              Subject     =>
                (if Identity.Sessions.Handles.Found (Handle)
                 then Identity.Operations.Audit.Subject_Of (Handle.Principal)
                 else Identity.Operations.Audit.No_Subject),
              Target      => Public_Reference,
              Outcome     =>
                Identity.Operations.Audit.Outcome_Of (Handle.Status),
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful renewal.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return (Status => Identity.Sessions.Handles.Unknown);
         end if;
      end;

      return Handle;
   end Execute;
end Identity.Operations.Sessions.Renew;
