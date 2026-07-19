package Identity.Operations.Cancellation is
   pragma Pure;

   type Cancellation_State is (Not_Cancelled, Cancellation_Requested);

   type Cancellation_Source is record
      State : Cancellation_State := Not_Cancelled;
   end record;

   function Cancelled (Source : Cancellation_Source) return Boolean is
     (Source.State = Cancellation_Requested);

   function Active (Source : Cancellation_Source) return Boolean is
     (Source.State = Not_Cancelled);
end Identity.Operations.Cancellation;
