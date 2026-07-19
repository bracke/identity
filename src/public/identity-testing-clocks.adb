package body Identity.Testing.Clocks is
   procedure Advance
     (Clock : in out Manual_Clock;
      By    : Identity.Times.Duration_Seconds)
   is
      Ok : Boolean := False;
   begin
      Clock.Current := Identity.Times.Add (Clock.Current, By, Ok);
      if not Ok then
         Clock.Current := Identity.Times.Instant'Last;
      end if;
   end Advance;
end Identity.Testing.Clocks;
