package Identity.Adapters.Repositories.Conformance is
   pragma Pure;

   type Certification_Profile is
     (Core_Identity_Store,
      Interactive_Authentication_Store,
      Session_Store,
      Recovery_Store,
      Federated_Identity_Store);

   type Conformance_Status is (Not_Run, Passed, Failed, Unsupported_Profile);

   function Not_Run_Status (Status : Conformance_Status) return Boolean is
     (Status = Not_Run);

   function Passed_Status (Status : Conformance_Status) return Boolean is
     (Status = Passed);

   function Failed_Status (Status : Conformance_Status) return Boolean is
     (Status = Failed);

   function Unsupported_Status (Status : Conformance_Status) return Boolean is
     (Status = Unsupported_Profile);

   function Terminal_Status (Status : Conformance_Status) return Boolean is
     (Status in Passed | Failed | Unsupported_Profile);

   function May_Advertise_Profile (Status : Conformance_Status) return Boolean is
     (Status = Passed);

   type Conformance_Result is record
      Profile : Certification_Profile := Core_Identity_Store;
      Status  : Conformance_Status := Not_Run;
   end record;

   function Required_Check_Count (Profile : Certification_Profile) return Positive is
     (case Profile is
        when Core_Identity_Store => 8,
        when Interactive_Authentication_Store => 11,
        when Session_Store => 9,
        when Recovery_Store => 10,
        when Federated_Identity_Store => 7);

   function Requires_Staged_External_Authentication
     (Profile : Certification_Profile) return Boolean is
     (Profile = Federated_Identity_Store);
end Identity.Adapters.Repositories.Conformance;
