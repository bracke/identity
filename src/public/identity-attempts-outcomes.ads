package Identity.Attempts.Outcomes is
   pragma Pure;

   type Attempt_Outcome is (Succeeded, Failed, Throttled, Conflict, Operational_Failure);
   type Failure_Category is
     (None,
      Password_Failure,
      TOTP_Failure,
      Recovery_Failure,
      Token_Failure,
      Provider_Failure,
      Session_Replay);
   type Disclosure_Category is (Generic_Rejection, Retry_Later, Public_Success, Hidden_Operational_Failure);

   function Successful (Outcome : Attempt_Outcome) return Boolean is
     (Outcome = Succeeded);

   function Failed (Outcome : Attempt_Outcome) return Boolean is
     (Outcome = Failed);

   function Throttled (Outcome : Attempt_Outcome) return Boolean is
     (Outcome = Throttled);

   function Conflict (Outcome : Attempt_Outcome) return Boolean is
     (Outcome = Conflict);

   function Operational (Outcome : Attempt_Outcome) return Boolean is
     (Outcome = Operational_Failure);

   function Counts_As_Credential_Failure
     (Outcome : Attempt_Outcome;
      Failure : Failure_Category) return Boolean is
     (Outcome = Failed and then Failure /= None);

   function No_Failure (Failure : Failure_Category) return Boolean is
     (Failure = None);
   function Password_Failed (Failure : Failure_Category) return Boolean is
     (Failure = Password_Failure);
   function TOTP_Failed (Failure : Failure_Category) return Boolean is
     (Failure = TOTP_Failure);
   function Recovery_Failed (Failure : Failure_Category) return Boolean is
     (Failure = Recovery_Failure);
   function Token_Failed (Failure : Failure_Category) return Boolean is
     (Failure = Token_Failure);
   function Provider_Failed (Failure : Failure_Category) return Boolean is
     (Failure = Provider_Failure);
   function Session_Replay_Detected
     (Failure : Failure_Category) return Boolean is
     (Failure = Session_Replay);
   function Counts_In_Failure_Bucket
     (Outcome : Attempt_Outcome;
      Failure : Failure_Category) return Boolean is
     (Counts_As_Credential_Failure (Outcome, Failure));
   function Security_Response_Failure
     (Failure : Failure_Category) return Boolean is
     (Failure in Session_Replay | Provider_Failure);

   function Generic_Public_Rejection
     (Disclosure : Disclosure_Category) return Boolean is
     (Disclosure in Generic_Rejection | Retry_Later);

   function Public_Success
     (Disclosure : Disclosure_Category) return Boolean is
     (Disclosure = Public_Success);

   function Hidden_Operational_Failure
     (Disclosure : Disclosure_Category) return Boolean is
     (Disclosure = Hidden_Operational_Failure);
end Identity.Attempts.Outcomes;
