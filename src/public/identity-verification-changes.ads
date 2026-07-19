with Identity.Identifiers.Entities;
with Identity.Versions;

package Identity.Verification.Changes is
   pragma Pure;

   type Contact_Change_State is
     (Change_Requested,
      Pending_New_Binding,
      New_Contact_Verification,
      Old_Contact_Confirmation,
      Cooling_Off,
      Activated,
      Cancelled,
      Expired);

   type Contact_Change_Action is
     (Begin_Change, Complete_New_Verification, Record_Old_Confirmation,
      Start_Cooling_Off, Activate_After_Gates, Cancel_Change, Expire_Change);

   type Contact_Change_Admission_Status is
     (Contact_Change_Admitted, Contact_Change_State_Rejected,
      Contact_Change_Terminal_Rejected);

   type Contact_Change_Record is record
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Predecessor : Identity.Identifiers.Entities.Contact_Binding_Id;
      Successor   : Identity.Identifiers.Entities.Contact_Binding_Id;
      Token       : Identity.Identifiers.Entities.Token_Id;
      State       : Contact_Change_State := Change_Requested;
      Version     : Identity.Versions.Entity_Version := 0;
   end record;

   function Is_Terminal (State : Contact_Change_State) return Boolean is
     (State in Activated | Cancelled | Expired);

   function Admission
     (State  : Contact_Change_State;
      Action : Contact_Change_Action) return Contact_Change_Admission_Status is
     (if Is_Terminal (State) then Contact_Change_Terminal_Rejected
      else
        (case Action is
            when Begin_Change =>
              (if State = Change_Requested
               then Contact_Change_Admitted
               else Contact_Change_State_Rejected),
            when Complete_New_Verification | Record_Old_Confirmation =>
              (if State = New_Contact_Verification
               then Contact_Change_Admitted
               else Contact_Change_State_Rejected),
            when Start_Cooling_Off =>
              (if State in New_Contact_Verification | Old_Contact_Confirmation
               then Contact_Change_Admitted
               else Contact_Change_State_Rejected),
            when Activate_After_Gates =>
              (if State in New_Contact_Verification | Old_Contact_Confirmation | Cooling_Off
               then Contact_Change_Admitted
               else Contact_Change_State_Rejected),
            when Cancel_Change | Expire_Change =>
              Contact_Change_Admitted));

   function Admission_Accepted
     (State  : Contact_Change_State;
      Action : Contact_Change_Action) return Boolean is
     (Admission (State, Action) = Contact_Change_Admitted);

   function Admission_Accepted
     (Status : Contact_Change_Admission_Status) return Boolean is
     (Status = Contact_Change_Admitted);

   function Admission_Rejected
     (Status : Contact_Change_Admission_Status) return Boolean is
     (Status /= Contact_Change_Admitted);

   function State_Rejected
     (Status : Contact_Change_Admission_Status) return Boolean is
     (Status = Contact_Change_State_Rejected);

   function Terminal_Rejected
     (Status : Contact_Change_Admission_Status) return Boolean is
     (Status = Contact_Change_Terminal_Rejected);

   function No_Mutation
     (Status : Contact_Change_Admission_Status) return Boolean is
     (Status /= Contact_Change_Admitted);

   function Can_Begin (State : Contact_Change_State) return Boolean is
     (Admission_Accepted (State, Begin_Change));

   function In_Progress (State : Contact_Change_State) return Boolean is
     (State not in Activated | Cancelled | Expired);

   function Awaiting_New_Contact_Verification
     (State : Contact_Change_State) return Boolean is
     (State = New_Contact_Verification);

   function Awaiting_Old_Contact_Confirmation
     (State : Contact_Change_State) return Boolean is
     (State = Old_Contact_Confirmation);

   function Cooling_Off_Active (State : Contact_Change_State) return Boolean is
     (State = Cooling_Off);

   function Activated_State (State : Contact_Change_State) return Boolean is
     (State = Activated);

   function Cancelled_State (State : Contact_Change_State) return Boolean is
     (State = Cancelled);

   function Expired_State (State : Contact_Change_State) return Boolean is
     (State = Expired);

   function Can_Cancel (State : Contact_Change_State) return Boolean is
     (Admission_Accepted (State, Cancel_Change));

   function Can_Expire (State : Contact_Change_State) return Boolean is
     (Admission_Accepted (State, Expire_Change));

   function Can_Complete (State : Contact_Change_State) return Boolean is
     (Admission_Accepted (State, Complete_New_Verification));

   function Can_Record_Old_Contact_Confirmation
     (State : Contact_Change_State) return Boolean is
     (Admission_Accepted (State, Record_Old_Confirmation));

   function Can_Start_Cooling_Off
     (State : Contact_Change_State) return Boolean is
     (Admission_Accepted (State, Start_Cooling_Off));

   function Can_Activate_After_Gates
     (State : Contact_Change_State) return Boolean is
     (Admission_Accepted (State, Activate_After_Gates));
end Identity.Verification.Changes;
