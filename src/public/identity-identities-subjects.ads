with Identity.Identifiers.Registry;
with Identity.Text.Bounded;

package Identity.Identities.Subjects is
   pragma Pure;

   type Authentication_Subject is record
      Kind  : Identity.Identifiers.Registry.Registry_Id;
      Value : Identity.Text.Bounded.Bounded_Text;
   end record;
end Identity.Identities.Subjects;
