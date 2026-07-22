with Identity.Events.Envelopes;
with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;

package body Identity.Operations.Factors.Accept_Passkey_Assertion is
   use type Identity.WebAuthn.Credentials.Assertion_Status;

   --  A verified, non-cloned assertion succeeds; a lost version check is a
   --  conflict; a cloned authenticator, an unusable or unknown credential is a
   --  rejection -- not a conflict.
   function Outcome_Of
     (Status : Identity.WebAuthn.Credentials.Assertion_Status)
      return Identity.Events.Envelopes.Event_Outcome is
     (case Status is
        when Identity.WebAuthn.Credentials.Accepted =>
          Identity.Events.Envelopes.Succeeded,
        when Identity.WebAuthn.Credentials.Version_Conflict =>
          Identity.Events.Envelopes.Conflict,
        when others =>
          Identity.Events.Envelopes.Rejected);
   function Execute
     (Repository       : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Credential       : Identity.Identifiers.Entities.Credential_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Expected_Version : Identity.Versions.Entity_Version;
      Presented        : Identity.WebAuthn.Credentials.Sign_Count;
      Context          : Identity.Operations.Contexts.Operation_Context;
      Event            : Identity.Identifiers.Entities.Event_Id;
      Recorded_At      : Identity.Times.Instant)
      return Identity.WebAuthn.Credentials.Assertion_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.WebAuthn.Credentials.Assertion_Status;
   begin
      --  Reserve first: a possession-factor verification -- and a detected
      --  cloned authenticator especially -- must not be applied silently.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.WebAuthn.Credentials.No_Mutation;
      end if;

      Status := Identity.Adapters.Repositories.Stores.Accept_Passkey_Assertion
        (Repository, Credential, Expected_Version, Presented);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.MFA_Challenge_Completed,
              Subject     => Identity.Operations.Audit.Subject_Of (Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Credential)),
              Outcome     => Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Identity.WebAuthn.Credentials.No_Mutation;
         end if;
      end;

      return Status;
   end Execute;
end Identity.Operations.Factors.Accept_Passkey_Assertion;
