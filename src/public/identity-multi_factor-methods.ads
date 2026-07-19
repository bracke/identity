with Identity.Authentication.Evidence;
with Identity.Identifiers.Registry;

package Identity.Multi_Factor.Methods is
   pragma Pure;

   type Method_Descriptor is record
      Id       : Identity.Identifiers.Registry.Registry_Id;
      Category : Identity.Authentication.Evidence.Factor_Category :=
        Identity.Authentication.Evidence.Possession;
      Active   : Boolean := True;
   end record;

   type MFA_Method_Admission_Status is
     (MFA_Method_Admitted,
      MFA_Method_Inactive,
      MFA_Method_Category_Rejected);

   function Admission (Value : Method_Descriptor)
      return MFA_Method_Admission_Status is
     (if not Value.Active then
         MFA_Method_Inactive
      elsif Value.Category not in
        Identity.Authentication.Evidence.Possession
        | Identity.Authentication.Evidence.Inherence
        | Identity.Authentication.Evidence.System_Attestation
      then
         MFA_Method_Category_Rejected
      else
         MFA_Method_Admitted);

   function Admission_Accepted
     (Status : MFA_Method_Admission_Status) return Boolean is
     (Status = MFA_Method_Admitted);

   function Admission_Rejected
     (Status : MFA_Method_Admission_Status) return Boolean is
     (Status /= MFA_Method_Admitted);

   function Inactive_Rejection
     (Status : MFA_Method_Admission_Status) return Boolean is
     (Status = MFA_Method_Inactive);

   function Category_Rejection
     (Status : MFA_Method_Admission_Status) return Boolean is
     (Status = MFA_Method_Category_Rejected);

   function Usable_For_MFA (Value : Method_Descriptor) return Boolean is
     (Admission_Accepted (Admission (Value)));
end Identity.Multi_Factor.Methods;
