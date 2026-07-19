package Identity.Credentials.States is
   pragma Pure;

   type Credential_State is (Created, Active, Replacement_Pending, Migrating, Expired, Locked, Retired, Revoked);

   type Credential_Authentication_Status is
     (Credential_Authentication_Admitted,
      Credential_Not_Activated,
      Credential_Replacement_Pending,
      Credential_Migration_Pending,
      Credential_Expired,
      Credential_Locked,
      Credential_Retired,
      Credential_Revoked);

   function Authentication_Admission
     (State : Credential_State) return Credential_Authentication_Status is
     (case State is
        when Active => Credential_Authentication_Admitted,
        when Created => Credential_Not_Activated,
        when Replacement_Pending => Credential_Replacement_Pending,
        when Migrating => Credential_Migration_Pending,
        when Expired => Credential_Expired,
        when Locked => Credential_Locked,
        when Retired => Credential_Retired,
        when Revoked => Credential_Revoked);

   function Authentication_Accepted
     (Status : Credential_Authentication_Status) return Boolean is
     (Status = Credential_Authentication_Admitted);

   function Authentication_Rejected
     (Status : Credential_Authentication_Status) return Boolean is
     (Status /= Credential_Authentication_Admitted);

   function Created_Rejection
     (Status : Credential_Authentication_Status) return Boolean is
     (Status = Credential_Not_Activated);

   function Replacement_Pending_Rejection
     (Status : Credential_Authentication_Status) return Boolean is
     (Status = Credential_Replacement_Pending);

   function Migration_Pending_Rejection
     (Status : Credential_Authentication_Status) return Boolean is
     (Status = Credential_Migration_Pending);

   function Expired_Rejection
     (Status : Credential_Authentication_Status) return Boolean is
     (Status = Credential_Expired);

   function Locked_Rejection
     (Status : Credential_Authentication_Status) return Boolean is
     (Status = Credential_Locked);

   function Retired_Rejection
     (Status : Credential_Authentication_Status) return Boolean is
     (Status = Credential_Retired);

   function Revoked_Rejection
     (Status : Credential_Authentication_Status) return Boolean is
     (Status = Credential_Revoked);

   function No_Mutation
     (Status : Credential_Authentication_Status) return Boolean is
     (Status /= Credential_Authentication_Admitted);

   function Can_Authenticate (State : Credential_State) return Boolean is
     (Authentication_Accepted (Authentication_Admission (State)));
end Identity.Credentials.States;
