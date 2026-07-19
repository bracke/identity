with Identity.Sessions.Definitions;
with Identity.Times;

package Identity.Sessions.Expiration is
   pragma Pure;

   type Expiration_Status is (Current, Idle_Expired, Absolute_Expired, Revoked);
   type Expiration_Detail is record
      Status           : Expiration_Status := Current;
      Idle_Expired     : Boolean := False;
      Absolute_Expired : Boolean := False;
      Revoked          : Boolean := False;
   end record;

   function Blocks_Continuity (Detail : Expiration_Detail) return Boolean is
     (Detail.Status /= Current);

   function Evaluate
     (Session : Identity.Sessions.Definitions.Session_Record;
      Now     : Identity.Times.Instant) return Expiration_Status;

   function Evaluate_Detail
     (Session : Identity.Sessions.Definitions.Session_Record;
      Now     : Identity.Times.Instant) return Expiration_Detail;

   function Allows_Continuity (Status : Expiration_Status) return Boolean is
     (Status = Current);

   function Rejects_Continuity (Status : Expiration_Status) return Boolean is
     (Status /= Current);

   function Idle_Timeout_Expired (Status : Expiration_Status) return Boolean is
     (Status = Idle_Expired);

   function Absolute_Lifetime_Expired
     (Status : Expiration_Status) return Boolean is
     (Status = Absolute_Expired);

   function Revocation_Blocks_Continuity
     (Status : Expiration_Status) return Boolean is
     (Status = Revoked);

   function Expiration_Blocks_Continuity
     (Status : Expiration_Status) return Boolean is
     (Status in Idle_Expired | Absolute_Expired);

   function Usable
     (Session : Identity.Sessions.Definitions.Session_Record;
      Now     : Identity.Times.Instant) return Boolean;
end Identity.Sessions.Expiration;
