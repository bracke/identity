with Identity.Events.Classification;

package Identity.Audit.Policies is
   pragma Pure;

   type Audit_Requirement is (Optional, Required);

   type Audit_Policy is record
      Sensitive_Events : Audit_Requirement := Required;
      Personal_Events  : Audit_Requirement := Required;
      Integrity_Required : Boolean := True;
   end record;

   type Audit_Policy_Validation_Status is
     (Audit_Policy_Valid,
      Audit_Sensitive_Events_Not_Required,
      Audit_Personal_Events_Not_Required,
      Audit_Integrity_Not_Required);

   function Requirement_For
     (Class : Identity.Events.Classification.Event_Data_Class) return Audit_Requirement is
     (if Class in Identity.Events.Classification.Sensitive | Identity.Events.Classification.Personal
      then Required
      else Optional);

   function Requirement_For
     (Value : Audit_Policy;
      Class : Identity.Events.Classification.Event_Data_Class) return Audit_Requirement is
     (case Class is
        when Identity.Events.Classification.Sensitive => Value.Sensitive_Events,
        when Identity.Events.Classification.Personal  => Value.Personal_Events,
        when others                                  => Optional);

   function Audit_Required
     (Value : Audit_Policy;
      Class : Identity.Events.Classification.Event_Data_Class) return Boolean is
     (Requirement_For (Value, Class) = Required);

   function Validate
     (Value : Audit_Policy) return Audit_Policy_Validation_Status is
     (if Value.Sensitive_Events /= Required then
        Audit_Sensitive_Events_Not_Required
      elsif Value.Personal_Events /= Required then
        Audit_Personal_Events_Not_Required
      elsif not Value.Integrity_Required then
        Audit_Integrity_Not_Required
      else
        Audit_Policy_Valid);

   function Validation_Accepted
     (Status : Audit_Policy_Validation_Status) return Boolean is
     (Status = Audit_Policy_Valid);

   function Requirement_Rejected
     (Status : Audit_Policy_Validation_Status) return Boolean is
     (Status in Audit_Sensitive_Events_Not_Required
              | Audit_Personal_Events_Not_Required);

   function Integrity_Rejected
     (Status : Audit_Policy_Validation_Status) return Boolean is
     (Status = Audit_Integrity_Not_Required);

   function Valid (Value : Audit_Policy) return Boolean is
     (Validation_Accepted (Validate (Value)));
end Identity.Audit.Policies;
