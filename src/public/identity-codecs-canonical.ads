with Identity.Text.Bounded;
with Identity.Versions;

package Identity.Codecs.Canonical
  with SPARK_Mode => On
is
   pragma Pure;

   function Frame
     (Version : Identity.Versions.Format_Version;
      Label   : Identity.Text.Bounded.Bounded_Text;
      Payload : Identity.Text.Bounded.Bounded_Text) return Identity.Text.Bounded.Bounded_Text
     with Pre => Identity.Text.Bounded.Length (Label) <= 96
       and then Identity.Text.Bounded.Length (Payload) <= 384;

   function Is_Canonical_Frame
     (Value : Identity.Text.Bounded.Bounded_Text) return Boolean;
end Identity.Codecs.Canonical;
