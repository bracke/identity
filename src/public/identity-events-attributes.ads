with Identity.Events.Classification;
with Identity.Events.Policies;
with Identity.Identifiers.Registry;
with Identity.Text.Bounded;

package Identity.Events.Attributes is
   pragma Pure;

   type Attribute_Status is
     (Accepted, Rejected_Key, Rejected_Class, Rejected_Policy);
   type Attribute_Value_Kind is (Text_Value, Integer_Value, Boolean_Value);

   type Event_Attribute is record
      Key           : Identity.Identifiers.Registry.Registry_Id;
      Data_Class    : Identity.Events.Classification.Event_Data_Class :=
        Identity.Events.Classification.Operational;
      Kind          : Attribute_Value_Kind := Text_Value;
      Text          : Identity.Text.Bounded.Bounded_Text;
      Integer_Data  : Integer := 0;
      Boolean_Data  : Boolean := False;
   end record;

   type Attribute_Result is record
      Status : Attribute_Status := Accepted;
      Value  : Event_Attribute;
   end record;

   function Accepted_Status (Status : Attribute_Status) return Boolean is
     (Status = Accepted);
   function Key_Rejected (Status : Attribute_Status) return Boolean is
     (Status = Rejected_Key);
   function Class_Rejected (Status : Attribute_Status) return Boolean is
     (Status = Rejected_Class);
   function Policy_Rejected (Status : Attribute_Status) return Boolean is
     (Status = Rejected_Policy);
   function Attribute_Rejected (Status : Attribute_Status) return Boolean is
     (Status in Rejected_Key | Rejected_Class | Rejected_Policy);

   function From_Text
     (Key        : Identity.Identifiers.Registry.Registry_Id;
      Data_Class : Identity.Events.Classification.Event_Data_Class;
      Value      : Identity.Text.Bounded.Bounded_Text) return Attribute_Result;

   function From_Text
     (Key        : Identity.Identifiers.Registry.Registry_Id;
      Data_Class : Identity.Events.Classification.Event_Data_Class;
      Value      : Identity.Text.Bounded.Bounded_Text;
      Policy     : Identity.Events.Policies.Event_Policy) return Attribute_Result;

   function From_Integer
     (Key        : Identity.Identifiers.Registry.Registry_Id;
      Data_Class : Identity.Events.Classification.Event_Data_Class;
      Value      : Integer) return Attribute_Result;

   function From_Integer
     (Key        : Identity.Identifiers.Registry.Registry_Id;
      Data_Class : Identity.Events.Classification.Event_Data_Class;
      Value      : Integer;
      Policy     : Identity.Events.Policies.Event_Policy) return Attribute_Result;

   function From_Boolean
     (Key        : Identity.Identifiers.Registry.Registry_Id;
      Data_Class : Identity.Events.Classification.Event_Data_Class;
      Value      : Boolean) return Attribute_Result;

   function From_Boolean
     (Key        : Identity.Identifiers.Registry.Registry_Id;
      Data_Class : Identity.Events.Classification.Event_Data_Class;
      Value      : Boolean;
      Policy     : Identity.Events.Policies.Event_Policy) return Attribute_Result;
end Identity.Events.Attributes;
