with Identity.Text.Bounded;

package Identity.Text.Redacted is
   pragma Pure;

   function Redacted return Identity.Text.Bounded.Bounded_Text is
     (Identity.Text.Bounded.From_String ("[identity-redacted]"));

   function Public_Or_Redacted
     (Value       : Identity.Text.Bounded.Bounded_Text;
      May_Disclose : Boolean) return Identity.Text.Bounded.Bounded_Text is
     (if May_Disclose then Value else Redacted);
end Identity.Text.Redacted;
