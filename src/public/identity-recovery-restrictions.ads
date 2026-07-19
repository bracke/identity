with Identity.Sessions.Policies;

package Identity.Recovery.Restrictions is
   pragma Pure;
   use type Identity.Sessions.Policies.Session_Request_Kind;

   type Recovery_Restrictions is record
      Restricted_Session : Boolean := True;
      Credential_Reestablishment_Required : Boolean := True;
      MFA_Reenrollment_Required : Boolean := False;
      Remember_Me_Prohibited : Boolean := True;
      Limited_Lifetime : Boolean := True;
   end record;

   type Session_Request_Admission_Mode is
     (Allow_Effective_Request, Require_Exact_Request);

   type Session_Request_Admission_Status is
     (Session_Request_Admitted,
      Persistent_Session_Reduced,
      Persistent_Session_Rejected);

   function Session_Request_Admission
     (Value   : Recovery_Restrictions;
      Request : Identity.Sessions.Policies.Session_Request_Kind;
      Mode    : Session_Request_Admission_Mode := Allow_Effective_Request)
      return Session_Request_Admission_Status is
     (if Request = Identity.Sessions.Policies.Persistent_Session
        and then Value.Remember_Me_Prohibited
      then
        (case Mode is
           when Allow_Effective_Request => Persistent_Session_Reduced,
           when Require_Exact_Request => Persistent_Session_Rejected)
      else Session_Request_Admitted);

   function Admission_Accepted
     (Status : Session_Request_Admission_Status) return Boolean is
     (Status in Session_Request_Admitted | Persistent_Session_Reduced);

   function Admission_Rejected
     (Status : Session_Request_Admission_Status) return Boolean is
     (Status = Persistent_Session_Rejected);

   function Reduced_To_Interactive
     (Status : Session_Request_Admission_Status) return Boolean is
     (Status = Persistent_Session_Reduced);

   function Persistent_Rejection
     (Status : Session_Request_Admission_Status) return Boolean is
     (Status = Persistent_Session_Rejected);

   function Restricted (Value : Recovery_Restrictions) return Boolean is
     (Value.Restricted_Session
      or else Value.Credential_Reestablishment_Required
      or else Value.MFA_Reenrollment_Required
      or else Value.Remember_Me_Prohibited
      or else Value.Limited_Lifetime);

   function Recovery_Authentication_Restricted
     (Value : Recovery_Restrictions) return Boolean is
     (Value.Restricted_Session
      and then Value.Credential_Reestablishment_Required
      and then Value.Remember_Me_Prohibited
      and then Value.Limited_Lifetime);

   function Allows_Session_Request
     (Value   : Recovery_Restrictions;
      Request : Identity.Sessions.Policies.Session_Request_Kind) return Boolean is
     (Admission_Accepted
        (Session_Request_Admission (Value, Request, Require_Exact_Request)));

   function Effective_Session_Request
     (Value   : Recovery_Restrictions;
      Request : Identity.Sessions.Policies.Session_Request_Kind)
      return Identity.Sessions.Policies.Session_Request_Kind is
     (if Value.Remember_Me_Prohibited
         and then Request = Identity.Sessions.Policies.Persistent_Session
      then Identity.Sessions.Policies.Interactive_Session
      else Request);

   function Requires_Limited_Session_Lifetime
     (Value : Recovery_Restrictions) return Boolean is
     (Value.Restricted_Session and then Value.Limited_Lifetime);

   function Downstream_Recovery_Restricted
     (Value : Recovery_Restrictions) return Boolean is
     (Restricted (Value)
      or else Requires_Limited_Session_Lifetime (Value)
      or else Value.Credential_Reestablishment_Required
      or else Value.MFA_Reenrollment_Required);
end Identity.Recovery.Restrictions;
