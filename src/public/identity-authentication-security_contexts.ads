with Identity.Assurance.Attributes;
with Identity.Assurance.Levels;
with Identity.Authentication.Evidence;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Limits;
with Identity.Principals.Kinds;
with Identity.Times;
with Identity.Times.Durations;
with Identity.Versions;

package Identity.Authentication.Security_Contexts is
   pragma Pure;

   type Authentication_State is (Anonymous, Authenticated);

   --  Authentication methods that produced this context (spec 4A), bounded by
   --  Identity.Limits.Max_Methods_Per_Context.
   type Context_Method is record
      Method   : Identity.Identifiers.Registry.Registry_Id;
      Category : Identity.Authentication.Evidence.Factor_Category :=
                   Identity.Authentication.Evidence.Knowledge;
   end record;
   subtype Method_Count is
     Natural range 0 .. Identity.Limits.Max_Methods_Per_Context;
   type Context_Method_Items is
     array (1 .. Identity.Limits.Max_Methods_Per_Context) of Context_Method;
   type Authentication_Method_Set is record
      Count : Method_Count := 0;
      Items : Context_Method_Items;
   end record;

   --  Safe references to the authentication events behind this context (spec
   --  4A): identifiers only, never event payloads.
   subtype Event_Ref_Count is
     Natural range 0 .. Identity.Limits.Max_Evidence_Per_Context;
   type Context_Event_Items is
     array (1 .. Identity.Limits.Max_Evidence_Per_Context)
       of Identity.Identifiers.Entities.Event_Id;
   type Authentication_Event_Refs is record
      Count : Event_Ref_Count := 0;
      Items : Context_Event_Items;
   end record;

   --  Approved external-provider reference (spec 4A), present only when the
   --  authentication was federated.
   type Optional_External_Provider (Present : Boolean := False) is record
      case Present is
         when True =>
            Value : Identity.Identifiers.Entities.External_Provider_Id;
         when False =>
            null;
      end case;
   end record;

   --  Structured recovery and credential-action restrictions (spec 4A/6),
   --  replacing the former lone Recovery_Restricted Boolean. Downstream
   --  consumers read these; Identity does not enforce resource access.
   type Action_Restrictions is record
      Recovery_Restricted                 : Boolean := False;
      No_Remember_Me                      : Boolean := False;
      Restricted_Session                  : Boolean := False;
      Password_Change_Required            : Boolean := False;
      MFA_Enrollment_Required             : Boolean := False;
      Credential_Reestablishment_Required : Boolean := False;
      Recent_Authentication_Required      : Boolean := False;
   end record;

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
            Methods               : Authentication_Method_Set;
            Provider              : Optional_External_Provider;
            Event_Refs            : Authentication_Event_Refs;
            Original_Authenticated_At : Identity.Times.Instant;
            Primary_Authenticated_At  : Identity.Times.Instant;
            MFA_Completed_At      : Optional_Instant;
            Step_Up_At            : Optional_Instant;
            Session               : Optional_Session_Id;
            Validity_Boundary     : Optional_Instant;
            Authentication_Revision : Identity.Versions.Authentication_State_Revision;
            Evidence_Revision     : Identity.Versions.Evidence_Revision;
            Session_Revision      : Identity.Versions.Session_Revision;
            Restrictions          : Action_Restrictions;
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

   --  Build an Authenticated security context. This is the producer the
   --  downstream projection uses (see Identity.Projections.Authentication):
   --  every field is supplied from already-projected authentication facts, so
   --  the Pure contract holds. Before this existed the Authenticated variant
   --  had no constructor and nothing could produce one.
   function Authenticated_Context
     (Principal                 : Identity.Identifiers.Entities.Principal_Id;
      Kind                      : Identity.Principals.Kinds.Principal_Kind;
      Assurance                 : Identity.Assurance.Levels.Assurance_Level;
      Attributes                : Identity.Assurance.Attributes.Assurance_Attributes;
      Original_Authenticated_At : Identity.Times.Instant;
      Primary_Authenticated_At  : Identity.Times.Instant;
      Revisions                 : Revision_Baseline;
      Methods                   : Authentication_Method_Set := (Count => 0, Items => <>);
      Provider                  : Optional_External_Provider := (Present => False);
      Event_Refs                : Authentication_Event_Refs := (Count => 0, Items => <>);
      MFA_Completed_At          : Optional_Instant := (Present => False);
      Step_Up_At                : Optional_Instant := (Present => False);
      Session                   : Optional_Session_Id := (Present => False);
      Validity_Boundary         : Optional_Instant := (Present => False);
      Restrictions              : Action_Restrictions := (others => False);
      Eligible                  : Boolean := True) return Security_Context;

   --  Derive the downstream revisions from the persisted entity versions they
   --  track. The revisions are not independent counters some operation must
   --  remember to bump: they ARE the account, evidence, and session versions,
   --  which the store already advances on every relevant change (account state
   --  transition, evidence change, session rotation/activity/assurance). A
   --  stale downstream context is detected by comparing these against a freshly
   --  derived baseline.
   function Revisions_From
     (Account_Version  : Identity.Versions.Entity_Version;
      Evidence_Version : Identity.Versions.Entity_Version;
      Session_Version  : Identity.Versions.Entity_Version;
      Session_Present  : Boolean) return Revision_Baseline;

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
