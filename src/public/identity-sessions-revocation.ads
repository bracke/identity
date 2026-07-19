package Identity.Sessions.Revocation is
   pragma Pure;

   type Revocation_Target is
     (One_Session,
      Session_Family,
      Principal_Sessions,
      Credential_Derived_Sessions,
      Provider_Derived_Sessions);

   type Revocation_Result is (Applied, Already_Revoked, Not_Found, Conflict);

   function Applied_Result (Result : Revocation_Result) return Boolean is
     (Result = Applied);

   function Already_Final (Result : Revocation_Result) return Boolean is
     (Result = Already_Revoked);

   function Missing_Target (Result : Revocation_Result) return Boolean is
     (Result = Not_Found);

   function Conflict_Result (Result : Revocation_Result) return Boolean is
     (Result = Conflict);

   function Revocation_Rejected (Result : Revocation_Result) return Boolean is
     (Result /= Applied);

   function No_Mutation (Result : Revocation_Result) return Boolean is
     (Result in Already_Revoked | Not_Found | Conflict);
end Identity.Sessions.Revocation;
