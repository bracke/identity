with Identity.Assurance.Attributes;
with Identity.Assurance.Levels;
with Identity.Identifiers.Entities;
with Identity.Sessions.Definitions;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

package Identity.Projections.Sessions is
   pragma Pure;

   Max_Session_Summaries : constant Natural := 128;

   type Session_Summary_Projection is record
      Id                 : Identity.Identifiers.Entities.Session_Id;
      Family             : Identity.Identifiers.Entities.Session_Family_Id;
      Principal          : Identity.Identifiers.Entities.Principal_Id;
      Assurance          : Identity.Assurance.Levels.Assurance_Level;
      Attributes         : Identity.Assurance.Attributes.Assurance_Attributes;
      Created_At         : Identity.Times.Instant;
      Original_Authenticated_At : Identity.Times.Instant;
      Primary_Authenticated_At  : Identity.Times.Instant;
      MFA_Completed_At          : Identity.Sessions.Definitions.Optional_Instant;
      Step_Up_At                : Identity.Sessions.Definitions.Optional_Instant;
      Last_Seen_At       : Identity.Times.Instant;
      Idle_Expires_At    : Identity.Times.Expiration;
      Absolute_Expires_At : Identity.Times.Expiration;
      Remembered         : Boolean;
      Generation         : Identity.Versions.Rotation_Generation;
      State              : Identity.Sessions.Definitions.Session_Revocation_State;
      Verifier_Present   : Boolean := False;
      Revision           : Identity.Versions.Session_Revision;
   end record;

   type Session_Summary_Array is
     array (Positive range 1 .. Max_Session_Summaries) of Session_Summary_Projection;

   type Session_Summary_List is record
      Count : Natural range 0 .. Max_Session_Summaries := 0;
      Items : Session_Summary_Array;
   end record;

   function Summary
     (Session : Identity.Sessions.Definitions.Session_Record)
      return Session_Summary_Projection is
     ((Id => Session.Id,
       Family => Session.Family,
       Principal => Session.Principal,
       Assurance => Session.Assurance,
       Attributes => Session.Attributes,
       Created_At => Session.Created_At,
       Original_Authenticated_At => Session.Original_Authenticated_At,
       Primary_Authenticated_At => Session.Primary_Authenticated_At,
       MFA_Completed_At => Session.MFA_Completed_At,
       Step_Up_At => Session.Step_Up_At,
       Last_Seen_At => Session.Last_Seen_At,
       Idle_Expires_At => Session.Idle_Expires_At,
       Absolute_Expires_At => Session.Absolute_Expires_At,
       Remembered => Session.Remembered,
       Generation => Session.Generation,
       State => Session.State,
       Verifier_Present =>
         not Identity.Text.Bounded.Equal
           (Session.Secret_Verifier, Identity.Text.Bounded.From_String ("")),
       Revision => Identity.Versions.Session_Revision (Session.Version)));

   function Lookup_Usable
     (Session : Session_Summary_Projection;
      Now     : Identity.Times.Instant) return Boolean is
     (Session.Verifier_Present
      and then Identity.Sessions.Definitions.Is_Active (Session.State)
      and then not Identity.Times.Expired (Now, Session.Idle_Expires_At)
      and then not Identity.Times.Expired (Now, Session.Absolute_Expires_At));

   function Terminal (Session : Session_Summary_Projection) return Boolean is
     (Identity.Sessions.Definitions.Is_Unusable (Session.State));
end Identity.Projections.Sessions;
