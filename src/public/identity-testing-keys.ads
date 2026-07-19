with Identity.Crypto.Domains;
with Identity.Crypto.Keys;
with Identity.Text.Bounded;

package Identity.Testing.Keys is
   function Active_API_Key return Identity.Crypto.Keys.Key_Reference is
     ((Key_Id => Identity.Text.Bounded.From_String ("testing-active-api-key"),
       Domain => Identity.Crypto.Domains.API_Key,
       State  => Identity.Crypto.Keys.Active));
end Identity.Testing.Keys;
