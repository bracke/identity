with Identity.Identifiers.Entities;
with Identity.Identifiers.Operations;
with Identity.Identifiers.Registry;
with Identity.Text.Bounded;

package Identity.Adapters.Notifications is
   type Delivery_Channel is (Email, SMS, Voice, Push, Out_Of_Band);
   type Delivery_Status is (Queued, Rejected, Unsupported_Channel, Infrastructure_Failure);
   type Post_Commit_Failure_Action is
     (No_Action,
      Retry_Without_Secret,
      Revoke_Issued_Authority,
      Issue_Replacement_Authority,
      Manual_Review);

   function Queued_Status (Status : Delivery_Status) return Boolean is
     (Status = Queued);

   function Rejected_Status (Status : Delivery_Status) return Boolean is
     (Status = Rejected);

   function Unsupported_Status (Status : Delivery_Status) return Boolean is
     (Status = Unsupported_Channel);

   function Infrastructure_Failed (Status : Delivery_Status) return Boolean is
     (Status = Infrastructure_Failure);

   function Delivery_Failed (Status : Delivery_Status) return Boolean is
     (Status in Rejected | Unsupported_Channel | Infrastructure_Failure);

   function Retryable_Delivery (Status : Delivery_Status) return Boolean is
     (Status = Infrastructure_Failure);

   type Delivery_Request is record
      Purpose     : Identity.Identifiers.Registry.Registry_Id;
      Correlation : Identity.Identifiers.Operations.Correlation_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Channel     : Delivery_Channel := Email;
      Destination_Label : Identity.Text.Bounded.Bounded_Text;
      Secret_Included   : Boolean := False;
   end record;

   type Delivery_Result is record
      Status : Delivery_Status := Unsupported_Channel;
      Request : Delivery_Request;
   end record;

   function Safe_For_Adapter (Request : Delivery_Request) return Boolean is
     (not Request.Secret_Included);

   function Delivery_Succeeded (Result : Delivery_Result) return Boolean is
     (Result.Status = Queued and then Safe_For_Adapter (Result.Request));

   function Failure_Action
     (Result : Delivery_Result) return Post_Commit_Failure_Action is
     (if Delivery_Succeeded (Result) then No_Action
      elsif not Safe_For_Adapter (Result.Request) then Revoke_Issued_Authority
      elsif Result.Status = Infrastructure_Failure then Retry_Without_Secret
      elsif Result.Status = Unsupported_Channel then Issue_Replacement_Authority
      else Manual_Review);
end Identity.Adapters.Notifications;
