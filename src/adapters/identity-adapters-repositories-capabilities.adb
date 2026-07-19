package body Identity.Adapters.Repositories.Capabilities is
   function Full_Memory_Profile return Repository_Capabilities is
     ((Security_Transitions          => True,
       Atomic_Mandatory_Events       => True,
       Optimistic_Versions           => True,
       Atomic_Session_Rotation       => True,
       Atomic_Token_Action           => True,
       Session_Family_Revocation     => True,
       Assertion_Replay_Registration => True,
       Idempotency                   => True,
       Deterministic_Event_Ordering  => True,
       Maximum_Atomic_Event_Count    => 64,
       Maximum_Command_Size          => 65_536));

   function Admit_Transaction
     (Capabilities     : Repository_Capabilities;
      Mode             : Identity.Adapters.Repositories.Transaction_Mode;
      Mandatory_Events : Boolean := False) return Capability_Admission
   is
   begin
      if Mode = Identity.Adapters.Repositories.Security_Transition
        and then not Capabilities.Security_Transitions
      then
         return Missing_Security_Transitions;
      elsif Mandatory_Events and then not Capabilities.Atomic_Mandatory_Events then
         return Missing_Atomic_Mandatory_Events;
      elsif Mode = Identity.Adapters.Repositories.Security_Transition
        and then not Capabilities.Optimistic_Versions
      then
         return Missing_Optimistic_Versions;
      else
         return Supported;
      end if;
   end Admit_Transaction;

   function Admit_Command
     (Capabilities : Repository_Capabilities;
      Requirement  : Atomic_Command_Requirement) return Capability_Admission
   is
   begin
      if Requirement.Requires_Session_Rotation
        and then not Capabilities.Atomic_Session_Rotation
      then
         return Missing_Atomic_Session_Rotation;
      elsif Requirement.Requires_Token_Action
        and then not Capabilities.Atomic_Token_Action
      then
         return Missing_Atomic_Token_Action;
      elsif Requirement.Requires_Family_Revocation
        and then not Capabilities.Session_Family_Revocation
      then
         return Missing_Session_Family_Revocation;
      elsif Requirement.Requires_Assertion_Replay
        and then not Capabilities.Assertion_Replay_Registration
      then
         return Missing_Assertion_Replay_Registration;
      elsif Requirement.Requires_Idempotency
        and then not Capabilities.Idempotency
      then
         return Missing_Idempotency;
      elsif Requirement.Requires_Deterministic_Ordering
        and then not Capabilities.Deterministic_Event_Ordering
      then
         return Missing_Deterministic_Event_Ordering;
      elsif Requirement.Requires_Mandatory_Events
        and then not Capabilities.Atomic_Mandatory_Events
      then
         return Missing_Atomic_Mandatory_Events;
      elsif Requirement.Requires_Optimistic_Versions
        and then not Capabilities.Optimistic_Versions
      then
         return Missing_Optimistic_Versions;
      elsif Requirement.Atomic_Event_Count > Capabilities.Maximum_Atomic_Event_Count then
         return Atomic_Event_Capacity_Exceeded;
      elsif Requirement.Command_Size > Capabilities.Maximum_Command_Size then
         return Command_Size_Exceeded;
      else
         return Supported;
      end if;
   end Admit_Command;
end Identity.Adapters.Repositories.Capabilities;
