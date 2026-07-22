with Identity.Text.Bounded;

--  Token binding: tie a session to the client it was issued to, so a stolen
--  bearer secret presented from a different client is detected rather than
--  silently accepted. The fingerprint is a non-secret value the caller derives
--  from the client -- a channel binding, a client public-key thumbprint, a
--  device key -- never the bearer secret itself. Rotation and replay detection
--  limit a stolen token's blast radius; this closes the window where a token
--  lifted from one client works from another.
package Identity.Sessions.Binding is
   pragma Pure;

   type Optional_Binding (Present : Boolean := False) is record
      case Present is
         when True =>
            Fingerprint : Identity.Text.Bounded.Bounded_Text;
         when False =>
            null;
      end case;
   end record;

   Unbound : constant Optional_Binding := (Present => False);

   type Binding_Match is (Unbound_Accepts_Any, Bound_Matched, Bound_Mismatch);

   --  An unbound session accepts any client (bearer semantics, unchanged). A
   --  bound session is usable only by a client whose fingerprint matches; any
   --  other presentation -- including none -- is a mismatch, the signal that a
   --  bound token is being replayed from a different client.
   function Evaluate
     (Stored    : Optional_Binding;
      Presented : Optional_Binding) return Binding_Match is
     (if not Stored.Present then Unbound_Accepts_Any
      elsif Presented.Present
        and then Identity.Text.Bounded.Equal
                   (Stored.Fingerprint, Presented.Fingerprint)
      then Bound_Matched
      else Bound_Mismatch);

   function Accepts (Match : Binding_Match) return Boolean is
     (Match in Unbound_Accepts_Any | Bound_Matched);
   function Theft_Signal (Match : Binding_Match) return Boolean is
     (Match = Bound_Mismatch);
end Identity.Sessions.Binding;
