package Identity.Adapters.Repositories.Capabilities is
   pragma Pure;

   type Capability_Admission is
     (Supported,
      Missing_Security_Transitions,
      Missing_Atomic_Mandatory_Events,
      Missing_Optimistic_Versions,
      Missing_Atomic_Session_Rotation,
      Missing_Atomic_Token_Action,
      Missing_Session_Family_Revocation,
      Missing_Assertion_Replay_Registration,
      Missing_Idempotency,
      Missing_Deterministic_Event_Ordering,
      Atomic_Event_Capacity_Exceeded,
      Command_Size_Exceeded);

   type Atomic_Command_Requirement is record
      Requires_Session_Rotation       : Boolean := False;
      Requires_Token_Action           : Boolean := False;
      Requires_Family_Revocation      : Boolean := False;
      Requires_Assertion_Replay       : Boolean := False;
      Requires_Idempotency            : Boolean := False;
      Requires_Deterministic_Ordering : Boolean := False;
      Requires_Mandatory_Events       : Boolean := False;
      Requires_Optimistic_Versions    : Boolean := False;
      Atomic_Event_Count              : Natural := 0;
      Command_Size                    : Natural := 0;
   end record;

   type Repository_Capabilities is record
      Security_Transitions             : Boolean := False;
      Atomic_Mandatory_Events          : Boolean := False;
      Optimistic_Versions              : Boolean := False;
      Atomic_Session_Rotation          : Boolean := False;
      Atomic_Token_Action              : Boolean := False;
      Session_Family_Revocation        : Boolean := False;
      Assertion_Replay_Registration    : Boolean := False;
      Idempotency                      : Boolean := False;
      Deterministic_Event_Ordering     : Boolean := False;
      --  True only for adapters safe to share between tasks. The reference
      --  memory adapter is not; wrap it in
      --  Identity.Adapters.Repositories.Serialized to obtain a store that is.
      Concurrent_Access                : Boolean := False;
      Maximum_Atomic_Event_Count       : Natural := 0;
      Maximum_Command_Size             : Natural := 0;
   end record;

   function Full_Memory_Profile return Repository_Capabilities;

   function Admit_Transaction
     (Capabilities     : Repository_Capabilities;
      Mode             : Identity.Adapters.Repositories.Transaction_Mode;
      Mandatory_Events : Boolean := False) return Capability_Admission;

   function Admit_Command
     (Capabilities : Repository_Capabilities;
      Requirement  : Atomic_Command_Requirement) return Capability_Admission;
end Identity.Adapters.Repositories.Capabilities;
