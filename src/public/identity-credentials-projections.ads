with Identity.Credentials.States;
with Identity.Credentials.Definitions;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Versions;

package Identity.Credentials.Projections is
   pragma Pure;

   type Credential_Projection is record
      Id        : Identity.Identifiers.Entities.Credential_Id;
      Principal : Identity.Identifiers.Entities.Principal_Id;
      Kind      : Identity.Identifiers.Registry.Registry_Id;
      State     : Identity.Credentials.States.Credential_State := Identity.Credentials.States.Active;
      Version   : Identity.Versions.Entity_Version := 0;
   end record;

   function Summary
     (Credential : Identity.Credentials.Definitions.Credential_Record)
      return Credential_Projection is
     ((Id => Credential.Id,
       Principal => Credential.Principal,
       Kind => Credential.Kind,
       State => Credential.State,
       Version => Credential.Version));

   function Can_Authenticate
     (Credential : Credential_Projection) return Boolean is
     (Identity.Credentials.States.Can_Authenticate (Credential.State));

   function Terminal
     (Credential : Credential_Projection) return Boolean is
     (Credential.State in Identity.Credentials.States.Retired
                      | Identity.Credentials.States.Revoked);
end Identity.Credentials.Projections;
