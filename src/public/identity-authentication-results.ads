with Identity.Identifiers.Entities;
with Identity.Results;

package Identity.Authentication.Results is
   pragma Pure;

   type Optional_Principal (Present : Boolean := False) is record
      case Present is
         when True =>
            Value : Identity.Identifiers.Entities.Principal_Id;
         when False =>
            null;
      end case;
   end record;

   type Password_Authentication_Result is record
      Status    : Identity.Results.Operation_Status := Identity.Results.Rejected;
      Principal : Optional_Principal;
   end record;
end Identity.Authentication.Results;
