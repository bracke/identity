with Identity.Events.Types;

package body Identity.Events.Schemas is
   use type Identity.Identifiers.Registry.Registry_Id;

   V1 : constant Identity.Versions.Schema_Version := 1;

   function Make
     (Type_Id : Identity.Identifiers.Registry.Registry_Id;
      Class   : Identity.Events.Classification.Event_Data_Class)
      return Event_Type_Registration is
     ((Schema => (Type_Id => Type_Id, Version => V1, Active => True),
       Class => Class,
       Mandatory_Audit => True));

   function Registration_For
     (Type_Id : Identity.Identifiers.Registry.Registry_Id) return Event_Type_Registration is
   begin
      if Type_Id = Identity.Events.Types.Authentication_Succeeded then
         return Make (Type_Id, Identity.Events.Classification.Operational);
      elsif Type_Id = Identity.Events.Types.Authentication_Rejected then
         return Make (Type_Id, Identity.Events.Classification.Sensitive);
      elsif Type_Id = Identity.Events.Types.Session_Created then
         return Make (Type_Id, Identity.Events.Classification.Operational);
      elsif Type_Id = Identity.Events.Types.Session_Rotated then
         return Make (Type_Id, Identity.Events.Classification.Sensitive);
      elsif Type_Id = Identity.Events.Types.Session_Revoked then
         return Make (Type_Id, Identity.Events.Classification.Sensitive);
      elsif Type_Id = Identity.Events.Types.Password_Changed then
         return Make (Type_Id, Identity.Events.Classification.Sensitive);
      elsif Type_Id = Identity.Events.Types.Password_Reset_Requested then
         return Make (Type_Id, Identity.Events.Classification.Sensitive);
      elsif Type_Id = Identity.Events.Types.Password_Reset_Completed then
         return Make (Type_Id, Identity.Events.Classification.Sensitive);
      elsif Type_Id = Identity.Events.Types.Account_Disabled then
         return Make (Type_Id, Identity.Events.Classification.Sensitive);
      elsif Type_Id = Identity.Events.Types.Contact_Verified then
         return Make (Type_Id, Identity.Events.Classification.Personal);
      elsif Type_Id = Identity.Events.Types.MFA_Challenge_Completed then
         return Make (Type_Id, Identity.Events.Classification.Sensitive);
      elsif Type_Id = Identity.Events.Types.Recovery_Completed then
         return Make (Type_Id, Identity.Events.Classification.Sensitive);
      elsif Type_Id = Identity.Events.Types.API_Key_Authenticated then
         return Make (Type_Id, Identity.Events.Classification.Sensitive);
      elsif Type_Id = Identity.Events.Types.API_Key_Revoked then
         return Make (Type_Id, Identity.Events.Classification.Sensitive);
      elsif Type_Id = Identity.Events.Types.TOTP_Replay_Detected then
         return Make (Type_Id, Identity.Events.Classification.Sensitive);
      elsif Type_Id = Identity.Events.Types.External_Assertion_Replay_Detected then
         return Make (Type_Id, Identity.Events.Classification.Sensitive);
      else
         return
           (Schema =>
              (Type_Id => Type_Id,
               Version => V1,
               Active => False),
            Class => Identity.Events.Classification.Operational,
            Mandatory_Audit => False);
      end if;
   end Registration_For;

   function Known (Type_Id : Identity.Identifiers.Registry.Registry_Id) return Boolean is
     (Registration_For (Type_Id).Schema.Active);

   function Requires_Mandatory_Audit
     (Type_Id : Identity.Identifiers.Registry.Registry_Id) return Boolean is
     (Registration_For (Type_Id).Mandatory_Audit);
end Identity.Events.Schemas;
