with Identity.Times;

package Identity.Testing.Clocks is
   type Manual_Clock is record
      Current : Identity.Times.Instant := 0;
   end record;

   function Now (Clock : Manual_Clock) return Identity.Times.Instant is (Clock.Current);
   procedure Advance
     (Clock : in out Manual_Clock;
      By    : Identity.Times.Duration_Seconds);
end Identity.Testing.Clocks;
