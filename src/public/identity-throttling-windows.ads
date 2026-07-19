with Identity.Times;

package Identity.Throttling.Windows is
   pragma Pure;
   use type Identity.Times.Instant;

   type Observation_Window is record
      Started_At : Identity.Times.Instant := 0;
      Ends_At    : Identity.Times.Instant := 0;
   end record;

   function Active (Value : Observation_Window; Now : Identity.Times.Instant) return Boolean is
     (Now >= Value.Started_At and then Now < Value.Ends_At);
end Identity.Throttling.Windows;
