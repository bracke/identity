with Identity.Authentication.Results;
with Identity.Authentication.Security_Contexts;
with Identity.Results;
with Identity.Versions;

package Identity.Projections.Authentication is
   pragma Pure;

   type Authentication_Projection is record
      Status : Identity.Results.Operation_Status;
      Principal : Identity.Authentication.Results.Optional_Principal;
      Authentication_Revision : Identity.Versions.Authentication_State_Revision;
      Evidence_Revision       : Identity.Versions.Evidence_Revision;
   end record;

   subtype Security_Context_Projection is
     Identity.Authentication.Security_Contexts.Security_Context;
end Identity.Projections.Authentication;
