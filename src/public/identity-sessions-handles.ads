with Identity.Assurance.Attributes;
with Identity.Assurance.Levels;
with Identity.Identifiers.Entities;
with Identity.Sessions.Definitions;
with Identity.Times;
with Identity.Versions;

package Identity.Sessions.Handles is
   pragma Pure;

   type Session_Lookup_Status is (Found, Unknown, Not_Verified, Expired, Revoked);

   type Session_Handle (Status : Session_Lookup_Status := Unknown) is record
      case Status is
         when Found =>
            Session    : Identity.Identifiers.Entities.Session_Id;
            Principal  : Identity.Identifiers.Entities.Principal_Id;
            Assurance  : Identity.Assurance.Levels.Assurance_Level;
            Attributes : Identity.Assurance.Attributes.Assurance_Attributes;
            Original_Authenticated_At : Identity.Times.Instant;
            Primary_Authenticated_At  : Identity.Times.Instant;
            MFA_Completed_At          : Identity.Sessions.Definitions.Optional_Instant;
            Step_Up_At                : Identity.Sessions.Definitions.Optional_Instant;
            Last_Seen_At : Identity.Times.Instant;
            Revision   : Identity.Versions.Session_Revision;
         when Unknown | Not_Verified | Expired | Revoked =>
            null;
      end case;
   end record;

   function Found (Status : Session_Lookup_Status) return Boolean is
     (Status = Found);

   function Disclosure_Collapsed_Invalid
     (Status : Session_Lookup_Status) return Boolean is
     (Status = Unknown or else Status = Not_Verified);

   function Unknown_Status (Status : Session_Lookup_Status) return Boolean is
     (Status = Unknown);

   function Not_Verified_Status
     (Status : Session_Lookup_Status) return Boolean is
     (Status = Not_Verified);

   function Retryable_By_Presentation
     (Status : Session_Lookup_Status) return Boolean is
     (Status = Unknown or else Status = Not_Verified);

   function Expired (Status : Session_Lookup_Status) return Boolean is
     (Status = Expired);

   function Revoked (Status : Session_Lookup_Status) return Boolean is
     (Status = Revoked);

   function Rejected (Status : Session_Lookup_Status) return Boolean is
     (Status /= Found);

   function Terminal_Rejection (Status : Session_Lookup_Status) return Boolean is
     (Status = Expired or else Status = Revoked);

   function Found (Handle : Session_Handle) return Boolean is
     (Found (Handle.Status));

   function Rejected (Handle : Session_Handle) return Boolean is
     (Rejected (Handle.Status));
end Identity.Sessions.Handles;
