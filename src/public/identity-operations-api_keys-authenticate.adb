with Identity.Events.Envelopes;
with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Results;

package body Identity.Operations.API_Keys.Authenticate is
   function Execute
     (Repository    : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Public_Key_Id : Identity.Text.Bounded.Bounded_Text;
      Secret        : Identity.Secrets.API_Keys.API_Key_Secret;
      Now           : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result is
   begin
      return Identity.Adapters.Repositories.Stores.Authenticate_API_Key
        (Repository, Public_Key_Id, Secret, Now);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Authentication_Request)
      return Identity.Authentication.Results.Password_Authentication_Result is
   begin
      return Identity.Adapters.Repositories.Stores.Authenticate_API_Key
        (Repository,
         Request.Public_Key_Id,
         Request.Secret,
         Request.Now,
         Request.Expected_Credential_Version);
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Authentication_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      use type Identity.Results.Operation_Status;

      Result : Identity.Authentication.Results.Password_Authentication_Result;
   begin
      --  Reserve first: refusing here leaves the credential's last-use state
      --  untouched.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return
           (Status    => Identity.Results.Operational_Failure,
            Principal => (Present => False));
      end if;

      Result := Execute (Repository, Request);

      declare
         --  An unusable or unmatched key is a rejection, not a store
         --  conflict, so the outcome is stated rather than derived from a
         --  command status.
         Outcome : constant Identity.Events.Envelopes.Event_Outcome :=
           (if Result.Status = Identity.Results.Succeeded
            then Identity.Events.Envelopes.Succeeded
            elsif Result.Status = Identity.Results.Conflict
            then Identity.Events.Envelopes.Conflict
            elsif Identity.Results.Operational (Result.Status)
            then Identity.Events.Envelopes.Failed
            else Identity.Events.Envelopes.Rejected);

         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.API_Key_Authenticated,
              Subject     =>
                (if Result.Principal.Present
                 then Identity.Operations.Audit.Subject_Of
                        (Result.Principal.Value)
                 else Identity.Operations.Audit.No_Subject),
              Target      => Request.Public_Key_Id,
              Outcome     => Outcome,
              Recorded_At => Recorded_At);
      begin
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return
              (Status    => Identity.Results.Operational_Failure,
               Principal => (Present => False));
         end if;
      end;

      return Result;
   end Execute;

   function Execute
     (Repository    : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Public_Key_Id : Identity.Text.Bounded.Bounded_Text;
      Secret        : Identity.Secrets.API_Keys.API_Key_Secret;
      Now           : Identity.Times.Instant;
      Context       : Identity.Operations.Contexts.Operation_Context;
      Event         : Identity.Identifiers.Entities.Event_Id;
      Recorded_At   : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      use type Identity.Results.Operation_Status;

      Result : Identity.Authentication.Results.Password_Authentication_Result;
   begin
      --  Reserve first: refusing here leaves the credential's last-use state
      --  untouched.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return
           (Status    => Identity.Results.Operational_Failure,
               Principal => (Present => False));
      end if;

      Result := Execute (Repository, Public_Key_Id, Secret, Now);

      declare
         --  An unusable or unmatched key is a rejection, not a store
         --  conflict, so the outcome is stated rather than derived from a
         --  command status.
         Outcome : constant Identity.Events.Envelopes.Event_Outcome :=
           (if Result.Status = Identity.Results.Succeeded
            then Identity.Events.Envelopes.Succeeded
            elsif Result.Status = Identity.Results.Conflict
            then Identity.Events.Envelopes.Conflict
            elsif Identity.Results.Operational (Result.Status)
            then Identity.Events.Envelopes.Failed
            else Identity.Events.Envelopes.Rejected);

         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.API_Key_Authenticated,
              Subject     =>
                (if Result.Principal.Present
                 then Identity.Operations.Audit.Subject_Of
                        (Result.Principal.Value)
                 else Identity.Operations.Audit.No_Subject),
              Target      => Public_Key_Id,
              Outcome     => Outcome,
              Recorded_At => Recorded_At);
      begin
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return
              (Status    => Identity.Results.Operational_Failure,
                 Principal => (Present => False));
         end if;
      end;

      return Result;
   end Execute;
end Identity.Operations.API_Keys.Authenticate;
