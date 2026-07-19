with Identity.Events.Classification;
with Identity.Limits;

package Identity.Events.Policies is
   pragma Pure;

   type Event_Policy is record
      Maximum_Attributes               : Natural := Identity.Limits.Max_Event_Attributes;
      Secret_Event_Attributes_Allowed  : Boolean := False;
      Derived_Event_Attributes_Allowed : Boolean := False;
      Post_Commit_Publication_Only     : Boolean := True;
   end record;

   type Event_Policy_Validation_Status is
     (Event_Policy_Valid,
      Event_Maximum_Attributes_Too_High,
      Event_Secret_Attributes_Allowed,
      Event_Derived_Secret_Attributes_Allowed,
      Event_Publication_Before_Commit_Allowed);

   function Attribute_Class_Allowed
     (Value : Event_Policy;
      Class : Identity.Events.Classification.Event_Data_Class) return Boolean is
     (case Class is
        when Identity.Events.Classification.Secret =>
          Value.Secret_Event_Attributes_Allowed,
        when Identity.Events.Classification.Derived_Secret =>
          Value.Derived_Event_Attributes_Allowed,
        when others =>
          True);

   function Validate
     (Value : Event_Policy) return Event_Policy_Validation_Status is
     (if Value.Maximum_Attributes > Identity.Limits.Max_Event_Attributes then
        Event_Maximum_Attributes_Too_High
      elsif Value.Secret_Event_Attributes_Allowed then
        Event_Secret_Attributes_Allowed
      elsif Value.Derived_Event_Attributes_Allowed then
        Event_Derived_Secret_Attributes_Allowed
      elsif not Value.Post_Commit_Publication_Only then
        Event_Publication_Before_Commit_Allowed
      else
        Event_Policy_Valid);

   function Validation_Accepted
     (Status : Event_Policy_Validation_Status) return Boolean is
     (Status = Event_Policy_Valid);

   function Attribute_Capacity_Rejected
     (Status : Event_Policy_Validation_Status) return Boolean is
     (Status = Event_Maximum_Attributes_Too_High);

   function Secret_Attribute_Rejected
     (Status : Event_Policy_Validation_Status) return Boolean is
     (Status in Event_Secret_Attributes_Allowed
              | Event_Derived_Secret_Attributes_Allowed);

   function Publication_Timing_Rejected
     (Status : Event_Policy_Validation_Status) return Boolean is
     (Status = Event_Publication_Before_Commit_Allowed);

   function Valid (Value : Event_Policy) return Boolean is
     (Validation_Accepted (Validate (Value)));
end Identity.Events.Policies;
