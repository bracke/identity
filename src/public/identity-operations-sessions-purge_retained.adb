with Identity.Events.Envelopes;
with Identity.Events.Types;
with Identity.Limits;
with Identity.Operations.Audit;
with Identity.Text.Bounded;

package body Identity.Operations.Sessions.Purge_Retained is
   use type Identity.Times.Instant;

   Seconds_Per_Day : constant Identity.Times.Instant := 86_400;

   function Retention_Boundary
     (Now    : Identity.Times.Instant;
      Policy : Identity.Policies.Snapshots.Session_Policy;
      Ok     : out Boolean) return Identity.Times.Instant
   is
      Span : Identity.Times.Instant;
   begin
      if Policy.Maximum_Retention_Days > Identity.Limits.Max_Session_Retention_Days then
         Ok := False;
         return Identity.Times.Instant'First;
      end if;

      Span := Identity.Times.Instant (Policy.Maximum_Retention_Days) * Seconds_Per_Day;

      if Now < Identity.Times.Instant'First + Span then
         Ok := False;
         return Identity.Times.Instant'First;
      end if;

      Ok := True;
      return Now - Span;
   end Retention_Boundary;

   function Execute
     (Repository   : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Retain_After : Identity.Times.Instant) return Natural is
   begin
      return Identity.Adapters.Repositories.Stores.Purge_Retained_Sessions
        (Repository, Retain_After);
   end Execute;

   --  "purged-sessions=<n>" -- a stable target that names the purge and
   --  carries how much it actually did, so one event stands in for the rows.
   function Affected_Target (Count : Natural) return Identity.Text.Bounded.Bounded_Text is
      Digits_Image : constant String := Natural'Image (Count);
   begin
      return Identity.Text.Bounded.From_String
        ("purged-sessions=" & Digits_Image (Digits_Image'First + 1 .. Digits_Image'Last));
   end Affected_Target;

   function Execute
     (Repository   : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Retain_After : Identity.Times.Instant;
      Context      : Identity.Operations.Contexts.Operation_Context;
      Event        : Identity.Identifiers.Entities.Event_Id;
      Recorded_At  : Identity.Times.Instant) return Natural
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Affected : Natural;
   begin
      --  Reserve first: a purge destroys the very rows an investigator would
      --  otherwise read, so refuse it outright rather than run it unrecorded.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return 0;
      end if;

      Affected := Execute (Repository, Retain_After);

      declare
         --  The purge has no verdict type of its own: reaching this point
         --  means it ran, and removing no rows is a successful empty purge.
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Session_Purged,
              Subject     => Identity.Operations.Audit.No_Subject,
              Target      => Affected_Target (Affected),
              Outcome     => Identity.Events.Envelopes.Succeeded,
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful purge.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return 0;
         end if;
      end;

      return Affected;
   end Execute;
end Identity.Operations.Sessions.Purge_Retained;
