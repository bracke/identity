package Identity.Events.Classification is
   pragma Pure;
   type Event_Data_Class is (Public, Operational, Personal, Sensitive, Secret, Derived_Secret);
   function Allowed_In_Ordinary_Event (Class : Event_Data_Class) return Boolean is
     (Class not in Secret | Derived_Secret);
end Identity.Events.Classification;
