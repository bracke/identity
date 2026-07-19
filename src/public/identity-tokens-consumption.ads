with Identity.Times;
with Identity.Tokens.Definitions;

package Identity.Tokens.Consumption is
   pragma Pure;

   type Consumption_Status is
     (Can_Consume,
      Already_Consumed,
      Expired,
      Revoked,
      Attempt_Limit_Reached,
      State_Conflict);

   function Consumable (Status : Consumption_Status) return Boolean is
     (Status = Can_Consume);

   function Consumption_Rejected
     (Status : Consumption_Status) return Boolean is
     (Status /= Can_Consume);

   function Already_Consumed_Rejection
     (Status : Consumption_Status) return Boolean is
     (Status = Already_Consumed);

   function Expired_Rejection
     (Status : Consumption_Status) return Boolean is
     (Status = Expired);

   function Revoked_Rejection
     (Status : Consumption_Status) return Boolean is
     (Status = Revoked);

   function Attempt_Limit_Rejection
     (Status : Consumption_Status) return Boolean is
     (Status = Attempt_Limit_Reached);

   function Conflict (Status : Consumption_Status) return Boolean is
     (Status = State_Conflict);

   function Terminal_Rejection
     (Status : Consumption_Status) return Boolean is
     (Status in Already_Consumed | Expired | Revoked | Attempt_Limit_Reached);

   function No_Protected_Mutation
     (Status : Consumption_Status) return Boolean is
     (Status /= Can_Consume);

   function Evaluate (State : Identity.Tokens.Definitions.Token_State) return Consumption_Status;

   function Evaluate
     (Token : Identity.Tokens.Definitions.Action_Token_Record;
      Now   : Identity.Times.Instant) return Consumption_Status;
end Identity.Tokens.Consumption;
