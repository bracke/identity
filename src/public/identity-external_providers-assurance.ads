with Identity.Assurance.Attributes;
with Identity.Assurance.Levels;
with Identity.Identifiers.Registry;

package Identity.External_Providers.Assurance is
   pragma Pure;

   type Provider_Assurance_Mapping is record
      Provider_Profile : Identity.Identifiers.Registry.Registry_Id;
      Local_Level      : Identity.Assurance.Levels.Assurance_Level :=
        Identity.Assurance.Levels.Basic;
      Attributes       : Identity.Assurance.Attributes.Assurance_Attributes;
      Additional_Local_Factor_Required : Boolean := False;
   end record;

   type Mapping_Status is (Mapped, Untrusted_Provider, Unsupported_Profile, Additional_Factor_Required);

   function Mapping_Accepted (Status : Mapping_Status) return Boolean is
     (Status = Mapped);

   function Mapping_Rejected (Status : Mapping_Status) return Boolean is
     (Status in Untrusted_Provider | Unsupported_Profile);

   function Provider_Rejected (Status : Mapping_Status) return Boolean is
     (Status = Untrusted_Provider);

   function Profile_Rejected (Status : Mapping_Status) return Boolean is
     (Status = Unsupported_Profile);

   function Requires_Additional_Factor
     (Status : Mapping_Status) return Boolean is
     (Status = Additional_Factor_Required);
end Identity.External_Providers.Assurance;
