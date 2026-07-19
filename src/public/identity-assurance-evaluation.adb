with Identity.Assurance.Profiles;

package body Identity.Assurance.Evaluation is
   function Requirements_For
     (Profile : Identity.Identifiers.Registry.Registry_Id)
      return Assurance_Profile_Requirements
   is
      use type Identity.Identifiers.Registry.Registry_Id;
   begin
      if Profile = Identity.Assurance.Profiles.Basic then
         return
           (Known => True,
            Level => Identity.Assurance.Levels.Basic,
            Minimum_Factors => 1,
            Minimum_Independent_Factors => 1,
            Require_Recent => False,
            Require_User_Verification => False,
            Permit_Recovery_Used => False);
      elsif Profile = Identity.Assurance.Profiles.Interactive then
         return
           (Known => True,
            Level => Identity.Assurance.Levels.Interactive,
            Minimum_Factors => 1,
            Minimum_Independent_Factors => 1,
            Require_Recent => True,
            Require_User_Verification => False,
            Permit_Recovery_Used => False);
      elsif Profile = Identity.Assurance.Profiles.Sensitive then
         return
           (Known => True,
            Level => Identity.Assurance.Levels.Sensitive,
            Minimum_Factors => 2,
            Minimum_Independent_Factors => 2,
            Require_Recent => True,
            Require_User_Verification => False,
            Permit_Recovery_Used => False);
      elsif Profile = Identity.Assurance.Profiles.Administrative then
         return
           (Known => True,
            Level => Identity.Assurance.Levels.Administrative,
            Minimum_Factors => 2,
            Minimum_Independent_Factors => 2,
            Require_Recent => True,
            Require_User_Verification => True,
            Permit_Recovery_Used => False);
      elsif Profile = Identity.Assurance.Profiles.Service then
         return
           (Known => True,
            Level => Identity.Assurance.Levels.Service,
            Minimum_Factors => 1,
            Minimum_Independent_Factors => 1,
            Require_Recent => False,
            Require_User_Verification => False,
            Permit_Recovery_Used => False);
      elsif Profile = Identity.Assurance.Profiles.Recovery_Restricted then
         return
           (Known => True,
            Level => Identity.Assurance.Levels.Basic,
            Minimum_Factors => 1,
            Minimum_Independent_Factors => 1,
            Require_Recent => False,
            Require_User_Verification => False,
            Permit_Recovery_Used => True);
      else
         return (others => <>);
      end if;
   end Requirements_For;

   function Evaluate
     (Profile    : Identity.Identifiers.Registry.Registry_Id;
      Attributes : Identity.Assurance.Attributes.Assurance_Attributes)
      return Assurance_Evaluation_Result
   is
      Requirements : constant Assurance_Profile_Requirements :=
        Requirements_For (Profile);
      Recovery_Restricted : constant Boolean :=
        Identity.Assurance.Attributes.Recovery_Restricted (Attributes);
   begin
      if not Requirements.Known then
         return
           (Satisfied => False,
            Level => Identity.Assurance.Levels.Anonymous,
            Recovery_Restricted => Recovery_Restricted);
      end if;

      return
        (Satisfied =>
           Identity.Assurance.Attributes.Meets_Factor_Floor
             (Attributes,
              Requirements.Minimum_Factors,
              Requirements.Minimum_Independent_Factors)
           and then (not Requirements.Require_Recent
                     or else Attributes.Recent_Authentication)
           and then (not Requirements.Require_User_Verification
                     or else Identity.Assurance.Attributes.Has_Verified_User
                       (Attributes))
           and then (Requirements.Permit_Recovery_Used
                     or else not Recovery_Restricted),
         Level => Requirements.Level,
         Recovery_Restricted => Recovery_Restricted);
   end Evaluate;
end Identity.Assurance.Evaluation;
