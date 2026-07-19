with Identity.Attempts.Definitions;
with Identity.Identifiers.Entities;
with Identity.Versions;

package Identity.Adapters.Repositories.Attempts is
   pragma Pure;

   type Attempt_Record_Status is (Recorded, Deferred, Capacity_Exceeded, Infrastructure_Failure);

   function Recorded_Status (Status : Attempt_Record_Status) return Boolean is
     (Status = Recorded);

   function Deferred_Status (Status : Attempt_Record_Status) return Boolean is
     (Status = Deferred);

   function Capacity_Rejected (Status : Attempt_Record_Status) return Boolean is
     (Status = Capacity_Exceeded);

   function Infrastructure_Failed (Status : Attempt_Record_Status) return Boolean is
     (Status = Infrastructure_Failure);

   function Operational_Failure (Status : Attempt_Record_Status) return Boolean is
     (Status in Capacity_Exceeded | Infrastructure_Failure);

   type Attempt_Command is record
      Attempt_Id       : Identity.Identifiers.Entities.Attempt_Id;
      Attempt          : Identity.Attempts.Definitions.Attempt_Record;
      Expected_Version : Identity.Versions.Entity_Version := 0;
   end record;
end Identity.Adapters.Repositories.Attempts;
