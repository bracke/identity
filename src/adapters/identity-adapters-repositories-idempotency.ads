with Identity.Identifiers.Operations;
with Identity.Operations.Idempotency;
with Identity.Versions;

package Identity.Adapters.Repositories.Idempotency is
   pragma Pure;

   type Idempotency_Status is (Fresh, Replayed, In_Progress, Conflict, Capacity_Exceeded, Infrastructure_Failure);

   function Fresh_Status (Status : Idempotency_Status) return Boolean is
     (Status = Fresh);

   function Replayed_Status (Status : Idempotency_Status) return Boolean is
     (Status = Replayed);

   function In_Progress_Status (Status : Idempotency_Status) return Boolean is
     (Status = In_Progress);

   function Conflict_Status (Status : Idempotency_Status) return Boolean is
     (Status = Conflict);

   function Capacity_Rejected (Status : Idempotency_Status) return Boolean is
     (Status = Capacity_Exceeded);

   function Infrastructure_Failed (Status : Idempotency_Status) return Boolean is
     (Status = Infrastructure_Failure);

   function Operational_Failure (Status : Idempotency_Status) return Boolean is
     (Status in Capacity_Exceeded | Infrastructure_Failure);

   function Terminal_Status (Status : Idempotency_Status) return Boolean is
     (Status in Replayed | Conflict | Capacity_Exceeded | Infrastructure_Failure);

   type Idempotency_Record is record
      Status       : Idempotency_Status := Fresh;
      Operation_Id : Identity.Identifiers.Operations.Operation_Id;
      Version      : Identity.Versions.Entity_Version := 0;
   end record;

   type Reservation is record
      Status    : Idempotency_Status := Fresh;
      Operation : Identity.Operations.Idempotency.Idempotent_Operation_Kind :=
        Identity.Operations.Idempotency.Password_Reset_Request;
      Key       : Identity.Operations.Idempotency.Idempotency_Key :=
        Identity.Operations.Idempotency.From_String ("");
      Completed : Boolean := False;
      Version   : Identity.Versions.Entity_Version := 0;
   end record;

   function To_Operation_Result
     (Value : Reservation) return Identity.Operations.Idempotency.Idempotency_Result;
end Identity.Adapters.Repositories.Idempotency;
