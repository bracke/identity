with Identity.Adapters.Repositories.Stores;
with Identity.Assurance.Attributes;
with Identity.Assurance.Levels;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Operations.Idempotency;
with Identity.Operations.Replay;
with Identity.Secrets.Sessions;
with Identity.Sessions.Definitions;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.Sessions.Rotate is
   type Rotate_Request is record
      Predecessor         : Identity.Identifiers.Entities.Session_Id;
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

   type Staged_Rotate_Request is record
      Request                      : Rotate_Request;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
   end record;

   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Predecessor : Identity.Identifiers.Entities.Session_Id;
      Successor   : Identity.Sessions.Definitions.Session_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Rotate_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Rotate_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form. Emits identity.session.rotated for the transition, and
   --  refuses the operation if the store cannot accept that event, so a
   --  session is never rotated without its audit record.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Rotate_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Idempotent form. A client whose rotation response was lost retries with
   --  the same request; without a reserved key the retry would retire the
   --  successor it just received and hand back a third session, which is
   --  indistinguishable from token theft to a family-reuse detector.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Rotate_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant;
      Key         : Identity.Operations.Idempotency.Idempotency_Key)
      return Identity.Operations.Replay.Command_Outcome;
end Identity.Operations.Sessions.Rotate;
