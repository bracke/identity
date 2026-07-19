with Identity.Assurance.Attributes;
with Identity.Assurance.Levels;
with Identity.Identifiers.Entities;
with Identity.Principals.Kinds;
with Identity.Times;
with Identity.Times.Durations;
with Identity.Versions;

package Identity.Authentication.Security_Contexts is
   pragma Pure;

   type Authentication_State is (Anonymous, Authenticated);

   type Optional_Session_Id (Present : Boolean := False) is record
      case Present is
         when True =>
            Value : Identity.Identifiers.Entities.Session_Id;
         when False =>
            null;
      end case;
   end record;

   type Optional_Instant (Present : Boolean := False) is record
      case Present is
         when True =>
            Value : Identity.Times.Instant;
         when False =>
            null;
      end case;
   end record;

   type Security_Context (State : Authentication_State := Anonymous) is record
      case State is
         when Anonymous =>
            Valid_Until : Optional_Instant;
         when Authenticated =>
            Principal             : Identity.Identifiers.Entities.Principal_Id;
            Kind                  : Identity.Principals.Kinds.Principal_Kind;
            Assurance             : Identity.Assurance.Levels.Assurance_Level;
            Attributes            : Identity.Assurance.Attributes.Assurance_Attributes;
            Original_Authenticated_At : Identity.Times.Instant;
            Primary_Authenticated_At  : Identity.Times.Instant;
            MFA_Completed_At      : Optional_Instant;
            Step_Up_At            : Optional_Instant;
            Session               : Optional_Session_Id;
            Validity_Boundary     : Optional_Instant;
            Authentication_Revision : Identity.Versions.Authentication_State_Revision;
            Evidence_Revision     : Identity.Versions.Evidence_Revision;
            Session_Revision      : Identity.Versions.Session_Revision;
            Recovery_Restricted   : Boolean;
            Eligible              : Boolean;
      end case;
   end record;

   type Revision_Baseline is record
      Authentication : Identity.Versions.Authentication_State_Revision := 0;
      Evidence       : Identity.Versions.Evidence_Revision := 0;
      Session        : Identity.Versions.Session_Revision := 0;
      Session_Present : Boolean := False;
   end record;

   type Context_Admission_Status is
     (Context_Usable,
      Stale_Revisions,
      Anonymous_Expired,
      Authenticated_Ineligible,
      Authenticated_Expired);

   function Anonymous_Context return Security_Context;
   function Current_Revisions (Context : Security_Context) return Revision_Baseline;
   function Revision_Changed
     (Context : Security_Context;
      Current : Revision_Baseline) return Boolean;
   function Has_Session (Context : Security_Context) return Boolean;
   function Admission_Status
     (Context : Security_Context;
      Current : Revision_Baseline;
      Now     : Identity.Times.Instant) return Context_Admission_Status;
   function Admission_Accepted
     (Status : Context_Admission_Status) return Boolean is
     (Status = Context_Usable);
   function Admission_Rejected
     (Status : Context_Admission_Status) return Boolean is
     (Status /= Context_Usable);
   function Stale_Revisions_Rejected
     (Status : Context_Admission_Status) return Boolean is
     (Status = Stale_Revisions);
   function Anonymous_Expiration_Rejected
     (Status : Context_Admission_Status) return Boolean is
     (Status = Anonymous_Expired);
   function Authenticated_Eligibility_Rejected
     (Status : Context_Admission_Status) return Boolean is
     (Status = Authenticated_Ineligible);
   function Authenticated_Expiration_Rejected
     (Status : Context_Admission_Status) return Boolean is
     (Status = Authenticated_Expired);
   function Usable_For_Downstream
     (Context : Security_Context;
      Current : Revision_Baseline;
      Now     : Identity.Times.Instant) return Boolean;
   function Original_Authentication_Recent
     (Context     : Security_Context;
      Now         : Identity.Times.Instant;
      Maximum_Age : Identity.Times.Durations.Authentication_Maximum_Age)
      return Boolean;
   function Primary_Authentication_Recent
     (Context     : Security_Context;
      Now         : Identity.Times.Instant;
      Maximum_Age : Identity.Times.Durations.Authentication_Maximum_Age)
      return Boolean;
   function MFA_Completion_Recent
     (Context     : Security_Context;
      Now         : Identity.Times.Instant;
      Maximum_Age : Identity.Times.Durations.Authentication_Maximum_Age)
      return Boolean;
   function Step_Up_Recent
     (Context     : Security_Context;
      Now         : Identity.Times.Instant;
      Maximum_Age : Identity.Times.Durations.Authentication_Maximum_Age)
      return Boolean;
end Identity.Authentication.Security_Contexts;
