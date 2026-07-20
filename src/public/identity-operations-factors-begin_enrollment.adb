with Identity.Credentials.States;
with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;

package body Identity.Operations.Factors.Begin_Enrollment is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Credential : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Begin_TOTP_Enrollment
        (Repository, Credential);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : TOTP_Begin_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Begin_TOTP_Enrollment
        (Repository,
         (Id              => Request.Id,
          Principal       => Request.Principal,
          Algorithm       => Request.Algorithm,
          Secret_Verifier => Identity.Text.Bounded.From_String (""),
          State           => Identity.Credentials.States.Created,
          Created_At      => Request.Created_At,
          Highest_Accepted_Counter => 0,
          Version         => 0));
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : TOTP_Begin_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve first: refusing here leaves the store untouched, whereas
      --  discovering a full event log afterwards would leave a pending factor
      --  nobody asked for on the record.
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
              Type_Id     => Identity.Events.Types.MFA_Enrollment_Began,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Request.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Request.Id)),
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

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Credential  : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve before mutating, exactly as the request form does: a
      --  transition that cannot be recorded is refused rather than applied.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Adapters.Repositories.Stores.Capacity_Conflict;
      end if;

      Status := Execute (Repository, Credential);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.MFA_Enrollment_Began,
              Subject     => Identity.Operations.Audit.Subject_Of (Credential.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Credential.Id)),
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
end Identity.Operations.Factors.Begin_Enrollment;
