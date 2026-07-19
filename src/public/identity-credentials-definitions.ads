with Identity.Credentials.States;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Versions;

package Identity.Credentials.Definitions is
   pragma Pure;

   type Credential_Record is record
      Id        : Identity.Identifiers.Entities.Credential_Id;
      Principal : Identity.Identifiers.Entities.Principal_Id;
      Kind      : Identity.Identifiers.Registry.Registry_Id;
      State     : Identity.Credentials.States.Credential_State := Identity.Credentials.States.Created;
      Version   : Identity.Versions.Entity_Version := 0;
   end record;
end Identity.Credentials.Definitions;
