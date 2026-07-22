with Identity.Identifiers.Operations;
with Identity.Text.Bounded;

--  The breach-check boundary the password acceptance policy's
--  Compromised_Check_Enabled flag was declared for but never had. The plaintext
--  password never crosses this boundary: the caller supplies a non-secret hash
--  prefix (k-anonymity, HIBP-style) and an adapter answers whether the full
--  hash is a known breached password. The core owns the admission decision; a
--  separate adapter crate owns the lookup, exactly as it owns notification
--  delivery.
package Identity.Adapters.Compromised_Passwords is
   pragma Pure;

   type Compromise_Verdict is (Clean, Compromised, Unavailable);

   type Compromise_Query is record
      Correlation : Identity.Identifiers.Operations.Correlation_Id;
      --  A non-secret prefix of the password's hash (e.g. the first bytes of
      --  its SHA-1 in hex, the HIBP range prefix). Never the password itself,
      --  and never its full hash.
      Hash_Prefix : Identity.Text.Bounded.Bounded_Text;
   end record;

   type Compromise_Result is record
      Verdict : Compromise_Verdict := Unavailable;
   end record;

   function Clean_Verdict (Value : Compromise_Verdict) return Boolean is
     (Value = Clean);
   function Compromised_Verdict (Value : Compromise_Verdict) return Boolean is
     (Value = Compromised);
   function Unavailable_Verdict (Value : Compromise_Verdict) return Boolean is
     (Value = Unavailable);

   type Password_Compromise_Admission is (Admitted, Rejected_Compromised);

   --  A compromised password is admitted only when the check is disabled; an
   --  unavailable check fails open, so a breach service that is down does not
   --  block every credential change (denial of service on password rotation is
   --  itself a security problem).
   function Admit
     (Check_Enabled : Boolean;
      Verdict       : Compromise_Verdict) return Password_Compromise_Admission is
     (if Check_Enabled and then Verdict = Compromised
      then Rejected_Compromised
      else Admitted);

   function Admitted_Password
     (Value : Password_Compromise_Admission) return Boolean is
     (Value = Admitted);
   function Rejected_Password
     (Value : Password_Compromise_Admission) return Boolean is
     (Value = Rejected_Compromised);
end Identity.Adapters.Compromised_Passwords;
