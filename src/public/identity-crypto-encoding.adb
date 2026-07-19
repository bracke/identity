with Identity.Codecs.Canonical;

package body Identity.Crypto.Encoding is
   function Canonical_Input
     (Version : Identity.Versions.Format_Version;
      Domain  : Identity.Identifiers.Registry.Registry_Id;
      Payload : Identity.Text.Bounded.Bounded_Text) return Identity.Text.Bounded.Bounded_Text
   is
   begin
      return Identity.Codecs.Canonical.Frame
        (Version,
         Identity.Text.Bounded.From_String (Identity.Identifiers.Registry.Image (Domain)),
         Payload);
   end Canonical_Input;
end Identity.Crypto.Encoding;
