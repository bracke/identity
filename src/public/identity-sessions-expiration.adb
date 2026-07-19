package body Identity.Sessions.Expiration is
   function Evaluate
     (Session : Identity.Sessions.Definitions.Session_Record;
      Now     : Identity.Times.Instant) return Expiration_Status
   is
   begin
      return Evaluate_Detail (Session, Now).Status;
   end Evaluate;

   function Evaluate_Detail
     (Session : Identity.Sessions.Definitions.Session_Record;
      Now     : Identity.Times.Instant) return Expiration_Detail
   is
      Has_Idle_Expired     : constant Boolean := Identity.Times.Expired (Now, Session.Idle_Expires_At);
      Has_Absolute_Expired : constant Boolean := Identity.Times.Expired (Now, Session.Absolute_Expires_At);
      Has_Revoked          : constant Boolean := not Identity.Sessions.Definitions.Is_Active (Session.State);
      Status           : Expiration_Status := Current;
   begin
      if Has_Revoked then
         Status := Revoked;
      elsif Has_Absolute_Expired then
         Status := Absolute_Expired;
      elsif Has_Idle_Expired then
         Status := Idle_Expired;
      end if;

      return
        (Status => Status,
         Idle_Expired => Has_Idle_Expired,
         Absolute_Expired => Has_Absolute_Expired,
         Revoked => Has_Revoked);
   end Evaluate_Detail;

   function Usable
     (Session : Identity.Sessions.Definitions.Session_Record;
      Now     : Identity.Times.Instant) return Boolean is
     (Allows_Continuity (Evaluate (Session, Now)));
end Identity.Sessions.Expiration;
