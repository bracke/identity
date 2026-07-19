package body Identity.Events.Attributes is
   function Rejected
     (Key        : Identity.Identifiers.Registry.Registry_Id;
      Data_Class : Identity.Events.Classification.Event_Data_Class;
      Status     : Attribute_Status := Rejected_Class) return Attribute_Result
   is
   begin
      return
        (Status => Status,
         Value  =>
           (Key          => Key,
            Data_Class   => Data_Class,
            Kind         => Text_Value,
            Text         => Identity.Text.Bounded.From_String (""),
            Integer_Data => 0,
            Boolean_Data => False));
   end Rejected;

   function From_Text
     (Key        : Identity.Identifiers.Registry.Registry_Id;
      Data_Class : Identity.Events.Classification.Event_Data_Class;
      Value      : Identity.Text.Bounded.Bounded_Text) return Attribute_Result
   is
   begin
      if not Identity.Identifiers.Registry.Is_Valid (Key) then
         return Rejected (Key, Data_Class, Rejected_Key);
      elsif not Identity.Events.Classification.Allowed_In_Ordinary_Event (Data_Class) then
         return Rejected (Key, Data_Class);
      end if;

      return
        (Status => Accepted,
         Value  =>
           (Key          => Key,
            Data_Class   => Data_Class,
            Kind         => Text_Value,
            Text         => Value,
            Integer_Data => 0,
            Boolean_Data => False));
   end From_Text;

   function From_Text
     (Key        : Identity.Identifiers.Registry.Registry_Id;
      Data_Class : Identity.Events.Classification.Event_Data_Class;
      Value      : Identity.Text.Bounded.Bounded_Text;
      Policy     : Identity.Events.Policies.Event_Policy) return Attribute_Result
   is
   begin
      if not Identity.Identifiers.Registry.Is_Valid (Key) then
         return Rejected (Key, Data_Class, Rejected_Key);
      elsif not Identity.Events.Policies.Valid (Policy) then
         return Rejected (Key, Data_Class, Rejected_Policy);
      elsif not Identity.Events.Policies.Attribute_Class_Allowed (Policy, Data_Class) then
         return Rejected (Key, Data_Class);
      else
         return From_Text (Key, Data_Class, Value);
      end if;
   end From_Text;

   function From_Integer
     (Key        : Identity.Identifiers.Registry.Registry_Id;
      Data_Class : Identity.Events.Classification.Event_Data_Class;
      Value      : Integer) return Attribute_Result
   is
   begin
      if not Identity.Identifiers.Registry.Is_Valid (Key) then
         return Rejected (Key, Data_Class, Rejected_Key);
      elsif not Identity.Events.Classification.Allowed_In_Ordinary_Event (Data_Class) then
         return Rejected (Key, Data_Class);
      end if;

      return
        (Status => Accepted,
         Value  =>
           (Key          => Key,
            Data_Class   => Data_Class,
            Kind         => Integer_Value,
            Text         => Identity.Text.Bounded.From_String (""),
            Integer_Data => Value,
            Boolean_Data => False));
   end From_Integer;

   function From_Integer
     (Key        : Identity.Identifiers.Registry.Registry_Id;
      Data_Class : Identity.Events.Classification.Event_Data_Class;
      Value      : Integer;
      Policy     : Identity.Events.Policies.Event_Policy) return Attribute_Result
   is
   begin
      if not Identity.Identifiers.Registry.Is_Valid (Key) then
         return Rejected (Key, Data_Class, Rejected_Key);
      elsif not Identity.Events.Policies.Valid (Policy) then
         return Rejected (Key, Data_Class, Rejected_Policy);
      elsif not Identity.Events.Policies.Attribute_Class_Allowed (Policy, Data_Class) then
         return Rejected (Key, Data_Class);
      else
         return From_Integer (Key, Data_Class, Value);
      end if;
   end From_Integer;

   function From_Boolean
     (Key        : Identity.Identifiers.Registry.Registry_Id;
      Data_Class : Identity.Events.Classification.Event_Data_Class;
      Value      : Boolean) return Attribute_Result
   is
   begin
      if not Identity.Identifiers.Registry.Is_Valid (Key) then
         return Rejected (Key, Data_Class, Rejected_Key);
      elsif not Identity.Events.Classification.Allowed_In_Ordinary_Event (Data_Class) then
         return Rejected (Key, Data_Class);
      end if;

      return
        (Status => Accepted,
         Value  =>
           (Key          => Key,
            Data_Class   => Data_Class,
            Kind         => Boolean_Value,
            Text         => Identity.Text.Bounded.From_String (""),
            Integer_Data => 0,
            Boolean_Data => Value));
   end From_Boolean;

   function From_Boolean
     (Key        : Identity.Identifiers.Registry.Registry_Id;
      Data_Class : Identity.Events.Classification.Event_Data_Class;
      Value      : Boolean;
      Policy     : Identity.Events.Policies.Event_Policy) return Attribute_Result
   is
   begin
      if not Identity.Identifiers.Registry.Is_Valid (Key) then
         return Rejected (Key, Data_Class, Rejected_Key);
      elsif not Identity.Events.Policies.Valid (Policy) then
         return Rejected (Key, Data_Class, Rejected_Policy);
      elsif not Identity.Events.Policies.Attribute_Class_Allowed (Policy, Data_Class) then
         return Rejected (Key, Data_Class);
      else
         return From_Boolean (Key, Data_Class, Value);
      end if;
   end From_Boolean;
end Identity.Events.Attributes;
