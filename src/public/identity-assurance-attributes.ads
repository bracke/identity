package Identity.Assurance.Attributes is
   pragma Pure;
   type Assurance_Attributes is record
      Factor_Count             : Natural := 0;
      Independent_Factor_Count : Natural := 0;
      Phishing_Resistant       : Boolean := False;
      Hardware_Bound           : Boolean := False;
      Device_Bound             : Boolean := False;
      Federation               : Boolean := False;
      Recovery_Used            : Boolean := False;
      User_Presence            : Boolean := False;
      User_Verification        : Boolean := False;
      Managed_Credential       : Boolean := False;
      Recent_Authentication    : Boolean := False;
   end record;

   function Consistent (Value : Assurance_Attributes) return Boolean is
     (Value.Independent_Factor_Count <= Value.Factor_Count
      and then (not Value.User_Verification or else Value.User_Presence));

   function Meets_Factor_Floor
     (Value                       : Assurance_Attributes;
      Minimum_Factors             : Natural;
      Minimum_Independent_Factors : Natural) return Boolean is
     (Consistent (Value)
      and then Value.Factor_Count >= Minimum_Factors
      and then Value.Independent_Factor_Count >= Minimum_Independent_Factors);

   function Has_Verified_User (Value : Assurance_Attributes) return Boolean is
     (Consistent (Value)
      and then Value.User_Presence
      and then Value.User_Verification);

   function Recovery_Restricted (Value : Assurance_Attributes) return Boolean is
     (Value.Recovery_Used);
end Identity.Assurance.Attributes;
