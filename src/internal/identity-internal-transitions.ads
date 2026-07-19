package Identity.Internal.Transitions is
   pragma Pure;

   type Transition_Kind is
     (Authentication_Finalization,
      Credential_Replacement,
      Session_Rotation,
      Token_Protected_Action,
      TOTP_Counter_Acceptance,
      Recovery_Code_Consumption,
      External_Assertion_Registration,
      Principal_Retirement);

   type Transition_Status is (Not_Started, Staged, Applied, Conflict, Rolled_Back, Faulted);
end Identity.Internal.Transitions;
