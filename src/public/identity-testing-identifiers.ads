with Identity.Identifiers;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Operations;

package Identity.Testing.Identifiers is
   function Principal_One return Identity.Identifiers.Entities.Principal_Id is
     (Identity.Identifiers.Entities.Principal
        (Identity.Identifiers.From_String ("00000000-0000-0000-0000-000000000001")));

   function Operation_One return Identity.Identifiers.Operations.Operation_Id is
     (Identity.Identifiers.Operations.Operation
        (Identity.Identifiers.From_String ("80000000-0000-0000-0000-000000000001")));
end Identity.Testing.Identifiers;
