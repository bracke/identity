package Identity.Sessions.Replay is
   pragma Pure;

   type Replay_Response is
     (Reject_Only,
      Revoke_Successor,
      Revoke_Family,
      Revoke_Principal_Sessions,
      Require_Reauthentication);

   function High_Severity (Value : Replay_Response) return Boolean is
     (Value in Revoke_Family | Revoke_Principal_Sessions | Require_Reauthentication);

   function Rejects_Presented (Value : Replay_Response) return Boolean is
     (Value in Reject_Only
       | Revoke_Successor
       | Revoke_Family
       | Revoke_Principal_Sessions
       | Require_Reauthentication);

   function Revokes_Successor (Value : Replay_Response) return Boolean is
     (Value in Revoke_Successor | Revoke_Family | Revoke_Principal_Sessions);

   function Revokes_Family (Value : Replay_Response) return Boolean is
     (Value in Revoke_Family | Revoke_Principal_Sessions);

   function Revokes_Principal_Sessions (Value : Replay_Response) return Boolean is
     (Value = Revoke_Principal_Sessions);

   function Revocation_Required (Value : Replay_Response) return Boolean is
     (Revokes_Successor (Value)
      or else Revokes_Family (Value)
      or else Revokes_Principal_Sessions (Value));

   function Requires_Reauthentication (Value : Replay_Response) return Boolean is
     (Value = Require_Reauthentication);
end Identity.Sessions.Replay;
