with Identity.Accounts.States;
with Identity.Assurance.Attributes;
with Identity.Assurance.Levels;
with Identity.Authentication.Results;
with Identity.Authentication.Security_Contexts;
with Identity.Identifiers.Entities;
with Identity.Principals.Kinds;
with Identity.Results;
with Identity.Times;
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

   --  The facts about the session backing an authenticated context, as an
   --  operation would gather them from a session lookup. Kept optional: a
   --  service-principal authentication has no session.
   type Optional_Session_Facts (Present : Boolean := False) is record
      case Present is
         when True =>
            Id                  : Identity.Identifiers.Entities.Session_Id;
            Version             : Identity.Versions.Entity_Version;
            Absolute_Expires_At :
              Identity.Authentication.Security_Contexts.Optional_Instant;
         when False =>
            null;
      end case;
   end record;

   --  Assemble a downstream security context (spec 4A) from projected
   --  authentication facts. This is the Identity-owned assembly the audit found
   --  missing: it derives the three revisions from the persisted versions, and
   --  derives eligibility and the structured restrictions from the account
   --  state view (Accounts.States.Evaluate plus the requirement and recovery
   --  flags) rather than trusting a caller to hand them in. A caller passes the
   --  principal, its assurance, the account state it just read, and the session
   --  it just looked up; the mapping lives here.
   function To_Security_Context
     (Principal                 : Identity.Identifiers.Entities.Principal_Id;
      Kind                      : Identity.Principals.Kinds.Principal_Kind;
      Assurance                 : Identity.Assurance.Levels.Assurance_Level;
      Attributes                : Identity.Assurance.Attributes.Assurance_Attributes;
      Account_State             : Identity.Accounts.States.Account_State_View;
      Account_Version           : Identity.Versions.Entity_Version;
      Original_Authenticated_At : Identity.Times.Instant;
      Primary_Authenticated_At  : Identity.Times.Instant;
      Evidence_Version          : Identity.Versions.Entity_Version := 0;
      Methods                   :
        Identity.Authentication.Security_Contexts.Authentication_Method_Set :=
          (Count => 0, Items => <>);
      Provider                  :
        Identity.Authentication.Security_Contexts.Optional_External_Provider :=
          (Present => False);
      Event_Refs                :
        Identity.Authentication.Security_Contexts.Authentication_Event_Refs :=
          (Count => 0, Items => <>);
      MFA_Completed_At          :
        Identity.Authentication.Security_Contexts.Optional_Instant :=
          (Present => False);
      Step_Up_At                :
        Identity.Authentication.Security_Contexts.Optional_Instant :=
          (Present => False);
      Session                   : Optional_Session_Facts := (Present => False))
      return Identity.Authentication.Security_Contexts.Security_Context;
end Identity.Projections.Authentication;
