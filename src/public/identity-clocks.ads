with Identity.Times;

package Identity.Clocks is
   type Clock is limited interface;
   function Now (Source : Clock) return Identity.Times.Instant is abstract;
end Identity.Clocks;
