with Identity.Crypto.Domains;
with Identity.Crypto.Secret_Verifiers;
with Identity.Events.Types;
with Identity.Operations.Audit;

package body Identity.Operations.Factors.Generate_Recovery_Codes is
   function To_Record (Request : Generate_Request)
      return Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record
   is
      Result : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record :=
        (Id         => Request.Id,
         Principal  => Request.Principal,
         Created_At => Request.Created_At,
         Version    => 0,
         Count      => Request.Count,
         Codes      => [others =>
           (Code_Id => Identity.Text.Bounded.From_String (""),
            Secret_Verifier => Identity.Text.Bounded.From_String (""),
            State => Identity.Recovery_Codes.Sets.Revoked)]);
   begin
      for Index in 1 .. Request.Count loop
         Result.Codes (Index) :=
           (Code_Id => Request.Codes (Index).Code_Id,
            Secret_Verifier => Identity.Crypto.Secret_Verifiers.Derive_Text
              (Identity.Crypto.Domains.Recovery_Code, Request.Codes (Index).Secret),
            State => Identity.Recovery_Codes.Sets.Active);
      end loop;
      return Result;
   end To_Record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Codes      : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Install_Recovery_Code_Set (Repository, Codes);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Generate_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Install_Recovery_Code_Set
        (Repository, To_Record (Request));
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Generate_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve first: refusing here leaves the store untouched, whereas
      --  discovering a full event log afterwards would install a new set of
      --  recovery secrets that nobody can trace back to a request.
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
              Type_Id     => Identity.Events.Types.Recovery_Codes_Generated,
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
end Identity.Operations.Factors.Generate_Recovery_Codes;
