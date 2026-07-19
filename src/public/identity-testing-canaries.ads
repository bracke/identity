with Identity.Text.Bounded;

package Identity.Testing.Canaries is
   function Distinctive_Text return Identity.Text.Bounded.Bounded_Text is
     (Identity.Text.Bounded.From_String ("IDENTITY-CANARY-SECRET"));
end Identity.Testing.Canaries;
