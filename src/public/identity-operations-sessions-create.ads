with Identity.Adapters.Repositories.Stores;
with Identity.Operations.Contexts;
with Identity.Assurance.Attributes;
with Identity.Assurance.Levels;
with Identity.Identifiers.Entities;
with Identity.Secrets.Sessions;
with Identity.Sessions.Definitions;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.Sessions.Create is
   type Create_Request is record
      Id                  : Identity.Identifiers.Entities.Session_Id;
      Family              : Identity.Identifiers.Entities.Session_Family_Id;
      Principal           : Identity.Identifiers.Entities.Principal_Id;
      Credential          : Identity.Sessions.Definitions.Optional_Credential_Id :=
        (Present => False);
      External_Provider   : Identity.Sessions.Definitions.Optional_External_Provider_Id :=
        (Present => False);
      Public_Reference    : Identity.Text.Bounded.Bounded_Text;
      Secret              : Identity.Secrets.Sessions.Session_Secret;
      Assurance           : Identity.Assurance.Levels.Assurance_Level :=
        Identity.Assurance.Levels.Basic;
      Attributes          : Identity.Assurance.Attributes.Assurance_Attributes;
      Created_At          : Identity.Times.Instant := 0;
      Original_Authenticated_At : Identity.Times.Instant := 0;
      Primary_Authenticated_At  : Identity.Times.Instant := 0;
      MFA_Completed_At          : Identity.Sessions.Definitions.Optional_Instant :=
        (Present => False);
      Step_Up_At                : Identity.Sessions.Definitions.Optional_Instant :=
        (Present => False);
      Last_Seen_At        : Identity.Times.Instant := 0;
      Idle_Expires_At     : Identity.Times.Expiration;
      Absolute_Expires_At : Identity.Times.Expiration;
      Remembered          : Boolean := False;
      Generation          : Identity.Versions.Rotation_Generation := 0;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Session    : Identity.Sessions.Definitions.Session_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Create_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form. Emits identity.session.created for the transition, and
   --  refuses the operation if the store cannot accept that event, so a
   --  session is never created without its audit record.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Create_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form taking the session record directly, for callers that
   --  have already built it.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Session     : Identity.Sessions.Definitions.Session_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Sessions.Create;
