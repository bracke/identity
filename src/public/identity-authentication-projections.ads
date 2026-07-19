with Identity.Assurance.Attributes;
with Identity.Assurance.Levels;
with Identity.Identifiers.Entities;
with Identity.Results;
with Identity.Times;
with Identity.Versions;

package Identity.Authentication.Projections is
   pragma Pure;

   type Optional_Principal (Present : Boolean := False) is record
      case Present is
         when True =>
            Value : Identity.Identifiers.Entities.Principal_Id;
         when False =>
            null;
      end case;
   end record;

   type Authentication_Projection is record
      Status : Identity.Results.Operation_Status := Identity.Results.Rejected;
      Principal : Optional_Principal;
      Assurance : Identity.Assurance.Levels.Assurance_Level := Identity.Assurance.Levels.Anonymous;
      Attributes : Identity.Assurance.Attributes.Assurance_Attributes;
      Authenticated_At : Identity.Times.Instant := 0;
      Authentication_Revision : Identity.Versions.Authentication_State_Revision := 0;
      Evidence_Revision : Identity.Versions.Evidence_Revision := 0;
   end record;
end Identity.Authentication.Projections;
