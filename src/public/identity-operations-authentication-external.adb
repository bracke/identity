with Identity.Events.Envelopes;
with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Results;

package body Identity.Operations.Authentication.External is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Assertion  : Identity.External_Providers.Assertions.Normalized_Assertion;
      Now        : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result is
   begin
      return Identity.Adapters.Repositories.Stores.Authenticate_External
        (Repository, Assertion, Now);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Authentication_Request;
      Now        : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result is
   begin
      return Identity.Adapters.Repositories.Stores.Authenticate_External
        (Repository,
         Request.Assertion,
         Now,
         Request.Expected_Binding_Version);
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Assertion   : Identity.External_Providers.Assertions.Normalized_Assertion;
      Now         : Identity.Times.Instant;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      use type Identity.Results.Operation_Status;

      Result : Identity.Authentication.Results.Password_Authentication_Result;
   begin
      --  Reserve before the fingerprint is registered: whether this assertion
      --  turns out to be a replay is only known afterwards, so the capacity
      --  for that event has to be held from the start.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return
           (Status    => Identity.Results.Operational_Failure,
            Principal => (Present => False));
      end if;

      Result := Execute (Repository, Assertion, Now);

      if Result.Status /= Identity.Results.Conflict then
         --  A rejected or unbound assertion is ordinary traffic; only the
         --  replay registration conflict is worth a security event.
         return Result;
      end if;

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     =>
                Identity.Events.Types.External_Assertion_Replay_Detected,
              Subject     => Identity.Operations.Audit.No_Subject,
              Target      => Assertion.Assertion_Fingerprint,
              Outcome     => Identity.Events.Envelopes.Conflict,
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store; a detected replay must never go unrecorded.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return
              (Status    => Identity.Results.Operational_Failure,
               Principal => (Present => False));
         end if;
      end;

      return Result;
   end Execute;
end Identity.Operations.Authentication.External;
