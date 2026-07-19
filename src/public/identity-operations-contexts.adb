package body Identity.Operations.Contexts is
   use type Identity.Times.Instant;

   function Evaluate_Deadline
     (Context : Operation_Context;
      Now     : Identity.Times.Instant) return Deadline_Status is
   begin
      if not Context.Deadline.Present then
         return No_Deadline;
      elsif Now < Context.Deadline.Time_Point then
         return Before_Deadline;
      elsif Now = Context.Deadline.Time_Point then
         return At_Deadline;
      else
         return Past_Deadline;
      end if;
   end Evaluate_Deadline;

   function Deadline_Exceeded
     (Context : Operation_Context;
      Now     : Identity.Times.Instant) return Boolean is
     (Evaluate_Deadline (Context, Now) = Past_Deadline);

   function Cancellation_Requested (Context : Operation_Context) return Boolean is
     (Identity.Operations.Cancellation.Cancelled (Context.Cancellation));

   function Evaluate_Checkpoint
     (Context : Operation_Context;
      Now     : Identity.Times.Instant) return Checkpoint_Status is
   begin
      if Cancellation_Requested (Context) then
         return Cancelled;
      elsif Deadline_Exceeded (Context, Now) then
         return Deadline_Exceeded;
      else
         return Continue;
      end if;
   end Evaluate_Checkpoint;
end Identity.Operations.Contexts;
