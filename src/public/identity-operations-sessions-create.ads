with Identity.Adapters.Repositories.Memory;
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
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Session    : Identity.Sessions.Definitions.Session_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Create_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status;
end Identity.Operations.Sessions.Create;
