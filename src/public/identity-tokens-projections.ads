with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Tokens.Definitions;
with Identity.Versions;

package Identity.Tokens.Projections is
   pragma Pure;

   type Token_Projection is record
      Id               : Identity.Identifiers.Entities.Token_Id;
      Purpose          : Identity.Identifiers.Registry.Registry_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Verifier_Present : Boolean := False;
      Issued_At        : Identity.Times.Instant := 0;
      Expires_At       : Identity.Times.Expiration;
      State            : Identity.Tokens.Definitions.Token_State := Identity.Tokens.Definitions.Issued;
      Attempts         : Identity.Versions.Attempt_Count := 0;
      Version          : Identity.Versions.Entity_Version := 0;
   end record;

   function Summary
     (Token : Identity.Tokens.Definitions.Action_Token_Record)
      return Token_Projection is
     ((Id => Token.Id,
       Purpose => Token.Purpose,
       Principal => Token.Principal,
       Verifier_Present =>
         not Identity.Text.Bounded.Equal
           (Token.Secret_Verifier, Identity.Text.Bounded.From_String ("")),
       Issued_At => Token.Issued_At,
       Expires_At => Token.Expires_At,
       State => Token.State,
       Attempts => Token.Attempts,
       Version => Token.Version));

   function Can_Verify
     (Token : Token_Projection;
      Now   : Identity.Times.Instant) return Boolean is
     (Token.Verifier_Present
      and then Identity.Tokens.Definitions.Can_Verify (Token.State)
      and then not Identity.Times.Expired (Now, Token.Expires_At));

   function Can_Complete
     (Token : Token_Projection;
      Now   : Identity.Times.Instant) return Boolean is
     (Token.Verifier_Present
      and then Identity.Tokens.Definitions.Can_Complete (Token.State)
      and then not Identity.Times.Expired (Now, Token.Expires_At));

   function Terminal (Token : Token_Projection) return Boolean is
     (Identity.Tokens.Definitions.Is_Terminal (Token.State));
end Identity.Tokens.Projections;
