with Identity.Audit.Records;

package Identity.Audit.Integrity is
   pragma Pure;

   use type Identity.Audit.Records.Integrity_State;

   function Not_Configured
     (State : Identity.Audit.Records.Integrity_State) return Boolean is
     (State = Identity.Audit.Records.Not_Configured);

   function Verified
     (State : Identity.Audit.Records.Integrity_State) return Boolean is
     (State = Identity.Audit.Records.Verified);

   function Failed
     (State : Identity.Audit.Records.Integrity_State) return Boolean is
     (State = Identity.Audit.Records.Failed);

   function Acceptable (State : Identity.Audit.Records.Integrity_State) return Boolean is
     (Not_Configured (State) or else Verified (State));
end Identity.Audit.Integrity;
