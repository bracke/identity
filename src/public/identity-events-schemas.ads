with Identity.Events.Classification;
with Identity.Identifiers.Registry;
with Identity.Versions;

package Identity.Events.Schemas is
   type Event_Schema is record
      Type_Id : Identity.Identifiers.Registry.Registry_Id;
      Version : Identity.Versions.Schema_Version := 1;
      Active  : Boolean := True;
   end record;

   type Event_Type_Registration is record
      Schema : Event_Schema;
      Class  : Identity.Events.Classification.Event_Data_Class :=
        Identity.Events.Classification.Operational;
      Mandatory_Audit : Boolean := True;
   end record;

   function Is_Active (Value : Event_Schema) return Boolean is (Value.Active);
   function Known (Type_Id : Identity.Identifiers.Registry.Registry_Id) return Boolean;
   function Registration_For
     (Type_Id : Identity.Identifiers.Registry.Registry_Id) return Event_Type_Registration;
   function Requires_Mandatory_Audit
     (Type_Id : Identity.Identifiers.Registry.Registry_Id) return Boolean;
end Identity.Events.Schemas;
