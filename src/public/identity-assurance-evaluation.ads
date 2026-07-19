with Identity.Assurance.Attributes;
with Identity.Assurance.Levels;
with Identity.Identifiers.Registry;

package Identity.Assurance.Evaluation is
   type Assurance_Profile_Requirements is record
      Known                       : Boolean := False;
      Level                       : Identity.Assurance.Levels.Assurance_Level :=
        Identity.Assurance.Levels.Anonymous;
      Minimum_Factors             : Natural := 0;
      Minimum_Independent_Factors : Natural := 0;
      Require_Recent              : Boolean := False;
      Require_User_Verification   : Boolean := False;
      Permit_Recovery_Used        : Boolean := False;
   end record;

   type Assurance_Evaluation_Result is record
      Satisfied : Boolean := False;
      Level     : Identity.Assurance.Levels.Assurance_Level :=
        Identity.Assurance.Levels.Anonymous;
      Recovery_Restricted : Boolean := False;
   end record;

   function Requirements_For
     (Profile : Identity.Identifiers.Registry.Registry_Id)
      return Assurance_Profile_Requirements;
   function Requirements_Known
     (Requirements : Assurance_Profile_Requirements) return Boolean is
     (Requirements.Known);
   function Requirements_Unknown
     (Requirements : Assurance_Profile_Requirements) return Boolean is
     (not Requirements.Known);

   function Evaluate
     (Profile    : Identity.Identifiers.Registry.Registry_Id;
      Attributes : Identity.Assurance.Attributes.Assurance_Attributes)
      return Assurance_Evaluation_Result;
   function Evaluation_Satisfied
     (Result : Assurance_Evaluation_Result) return Boolean is
     (Result.Satisfied);
   function Evaluation_Rejected
     (Result : Assurance_Evaluation_Result) return Boolean is
     (not Result.Satisfied);
   function Evaluation_Recovery_Restricted
     (Result : Assurance_Evaluation_Result) return Boolean is
     (Result.Recovery_Restricted);
end Identity.Assurance.Evaluation;
