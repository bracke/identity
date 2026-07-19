with Identity.Text.Bounded;
with Identity.Versions;

package Identity.Testing.Fixtures is
   type Fixture_Set is record
      Name           : Identity.Text.Bounded.Bounded_Text;
      Format_Version : Identity.Versions.Format_Version := 1;
      Deterministic  : Boolean := True;
   end record;

   function Default_Set return Fixture_Set is
     ((Name => Identity.Text.Bounded.From_String ("identity.default-fixtures"),
       Format_Version => 1,
       Deterministic => True));
end Identity.Testing.Fixtures;
