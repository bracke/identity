with Identity.Identifiers.Entities;
with Identity.Recovery.Restrictions;
with Identity.Sessions.Policies;
with Identity.Times;

package Identity.Recovery.Authority is
   pragma Pure;

   type Recovery_Authority_Record is record
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Expires_At : Identity.Times.Expiration;
      Short_Lived : Boolean := True;
      Password_Reestablishment_Required : Boolean := True;
   end record;

   type Recovery_Authority_Projection is record
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Expires_At : Identity.Times.Expiration;
      Short_Lived : Boolean := True;
      Password_Reestablishment_Required : Boolean := True;
      Expired : Boolean := False;
      Usable_Now : Boolean := False;
   end record;

   type Recovery_Authority_Usability_Status is
     (Recovery_Authority_Usable,
      Recovery_Authority_Not_Short_Lived,
      Recovery_Authority_Password_Reestablishment_Not_Required,
      Recovery_Authority_Expired,
      Recovery_Authority_Projection_Not_Usable);

   type Recovery_Authority_Issuance_Status is
     (Restricted_Authentication_Issuable,
      Recovery_Authority_Unusable,
      Recovery_Restrictions_Insufficient,
      Recovery_Session_Request_Rejected);

   function Usability
     (Value : Recovery_Authority_Record;
      Now   : Identity.Times.Instant)
      return Recovery_Authority_Usability_Status is
     (if not Value.Short_Lived then
         Recovery_Authority_Not_Short_Lived
      elsif not Value.Password_Reestablishment_Required then
         Recovery_Authority_Password_Reestablishment_Not_Required
      elsif Identity.Times.Expired (Now, Value.Expires_At) then
         Recovery_Authority_Expired
      else
         Recovery_Authority_Usable);

   function Usability
     (Value : Recovery_Authority_Projection)
      return Recovery_Authority_Usability_Status is
     (if not Value.Short_Lived then
         Recovery_Authority_Not_Short_Lived
      elsif not Value.Password_Reestablishment_Required then
         Recovery_Authority_Password_Reestablishment_Not_Required
      elsif Value.Expired then
         Recovery_Authority_Expired
      elsif not Value.Usable_Now then
         Recovery_Authority_Projection_Not_Usable
      else
         Recovery_Authority_Usable);

   function Usability_Accepted
     (Status : Recovery_Authority_Usability_Status) return Boolean is
     (Status = Recovery_Authority_Usable);

   function Short_Lived_Rejection
     (Status : Recovery_Authority_Usability_Status) return Boolean is
     (Status = Recovery_Authority_Not_Short_Lived);

   function Password_Reestablishment_Rejection
     (Status : Recovery_Authority_Usability_Status) return Boolean is
     (Status = Recovery_Authority_Password_Reestablishment_Not_Required);

   function Expired_Rejection
     (Status : Recovery_Authority_Usability_Status) return Boolean is
     (Status = Recovery_Authority_Expired);

   function Projection_Usability_Rejection
     (Status : Recovery_Authority_Usability_Status) return Boolean is
     (Status = Recovery_Authority_Projection_Not_Usable);

   function Usable
     (Value : Recovery_Authority_Record;
      Now   : Identity.Times.Instant) return Boolean is
     (Usability_Accepted (Usability (Value, Now)));

   function Summary
     (Value : Recovery_Authority_Record;
      Now   : Identity.Times.Instant) return Recovery_Authority_Projection is
     ((Principal  => Value.Principal,
       Expires_At => Value.Expires_At,
       Short_Lived => Value.Short_Lived,
       Password_Reestablishment_Required =>
         Value.Password_Reestablishment_Required,
       Expired => Identity.Times.Expired (Now, Value.Expires_At),
       Usable_Now => Usable (Value, Now)));

   function Usable (Value : Recovery_Authority_Projection) return Boolean is
     (Usability_Accepted (Usability (Value)));

   function Expired (Value : Recovery_Authority_Projection) return Boolean is
     (Value.Expired);

   function Requires_Password_Reestablishment
     (Value : Recovery_Authority_Projection) return Boolean is
     (Value.Password_Reestablishment_Required);

   function Requires_Restricted_Authentication
     (Authority    : Recovery_Authority_Projection;
      Restrictions : Identity.Recovery.Restrictions.Recovery_Restrictions)
      return Boolean is
     (Usable (Authority)
      and then Identity.Recovery.Restrictions.Recovery_Authentication_Restricted
        (Restrictions));

   function Issuance
     (Authority    : Recovery_Authority_Projection;
      Restrictions : Identity.Recovery.Restrictions.Recovery_Restrictions;
      Request      : Identity.Sessions.Policies.Session_Request_Kind)
      return Recovery_Authority_Issuance_Status is
     (if not Usable (Authority) then
         Recovery_Authority_Unusable
      elsif not Identity.Recovery.Restrictions.Recovery_Authentication_Restricted
        (Restrictions)
      then
         Recovery_Restrictions_Insufficient
      elsif Identity.Recovery.Restrictions.Persistent_Rejection
        (Identity.Recovery.Restrictions.Session_Request_Admission
           (Restrictions,
            Request,
            Identity.Recovery.Restrictions.Require_Exact_Request))
      then
         Recovery_Session_Request_Rejected
      else
         Restricted_Authentication_Issuable);

   function Issuance_Accepted
     (Status : Recovery_Authority_Issuance_Status) return Boolean is
     (Status = Restricted_Authentication_Issuable);

   function Issuance_Authority_Rejected
     (Status : Recovery_Authority_Issuance_Status) return Boolean is
     (Status = Recovery_Authority_Unusable);

   function Issuance_Restrictions_Rejected
     (Status : Recovery_Authority_Issuance_Status) return Boolean is
     (Status = Recovery_Restrictions_Insufficient);

   function Issuance_Session_Request_Rejected
     (Status : Recovery_Authority_Issuance_Status) return Boolean is
     (Status = Recovery_Session_Request_Rejected);

   function Can_Issue_Restricted_Authentication
     (Authority    : Recovery_Authority_Projection;
      Restrictions : Identity.Recovery.Restrictions.Recovery_Restrictions;
      Request      : Identity.Sessions.Policies.Session_Request_Kind)
      return Boolean is
     (Issuance_Accepted
        (Issuance (Authority, Restrictions, Request)));
end Identity.Recovery.Authority;
