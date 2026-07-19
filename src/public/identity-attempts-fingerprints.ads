with Identity.Text.Bounded;

package Identity.Attempts.Fingerprints is
   pragma Pure;

   type Subject_Fingerprint is record
      Value : Identity.Text.Bounded.Bounded_Text;
      Keyed : Boolean := True;
      Domain_Separated : Boolean := True;
   end record;

   function Safe_To_Persist (Value : Subject_Fingerprint) return Boolean is
     (Value.Keyed and then Value.Domain_Separated);
end Identity.Attempts.Fingerprints;
