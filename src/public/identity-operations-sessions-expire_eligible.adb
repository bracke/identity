with Identity.Events.Envelopes;
with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;

package body Identity.Operations.Sessions.Expire_Eligible is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Now        : Identity.Times.Instant) return Natural is
   begin
      return Identity.Adapters.Repositories.Stores.Expire_Eligible_Sessions
        (Repository, Now);
   end Execute;

   --  "expired-sessions=<n>" -- a stable target that names the sweep and
   --  carries how much it actually did, so one event stands in for the rows.
   function Affected_Target (Count : Natural) return Identity.Text.Bounded.Bounded_Text is
      Digits_Image : constant String := Natural'Image (Count);
   begin
      return Identity.Text.Bounded.From_String
        ("expired-sessions=" & Digits_Image (Digits_Image'First + 1 .. Digits_Image'Last));
   end Affected_Target;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Now         : Identity.Times.Instant;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant) return Natural
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Affected : Natural;
   begin
      --  Reserve first: refusing here leaves every eligible session alone,
      --  whereas a full event log discovered afterwards would have already
      --  expired them with nothing on record.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return 0;
      end if;

      Affected := Execute (Repository, Now);

      declare
         --  The sweep has no verdict type of its own: reaching this point
         --  means it ran, and touching no rows is a successful empty sweep.
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Session_Expired,
              Subject     => Identity.Operations.Audit.No_Subject,
              Target      => Affected_Target (Affected),
              Outcome     => Identity.Events.Envelopes.Succeeded,
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful sweep.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return 0;
         end if;
      end;

      return Affected;
   end Execute;
end Identity.Operations.Sessions.Expire_Eligible;
