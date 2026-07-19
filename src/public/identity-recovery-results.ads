package Identity.Recovery.Results is
   pragma Pure;

   type Recovery_Result_Status is
     (Started,
      Evidence_Required,
      Approved,
      Restricted_Authentication_Established,
      Completed,
      Rejected,
      Conflict,
      Operational_Failure);

   function In_Progress (Status : Recovery_Result_Status) return Boolean is
     (Status = Started
      or else Status = Evidence_Required
      or else Status = Approved);

   function Started_Status (Status : Recovery_Result_Status) return Boolean is
     (Status = Started);

   function Evidence_Required_Status
     (Status : Recovery_Result_Status) return Boolean is
     (Status = Evidence_Required);

   function Approved_Status (Status : Recovery_Result_Status) return Boolean is
     (Status = Approved);

   function Successful (Status : Recovery_Result_Status) return Boolean is
     (Status = Restricted_Authentication_Established
      or else Status = Completed);

   function Restricted (Status : Recovery_Result_Status) return Boolean is
     (Status = Restricted_Authentication_Established);

   function May_Issue_Restricted_Authentication
     (Status : Recovery_Result_Status) return Boolean is
     (Status = Restricted_Authentication_Established);

   function Final_Completion (Status : Recovery_Result_Status) return Boolean is
     (Status = Completed);

   function Failed (Status : Recovery_Result_Status) return Boolean is
     (Status = Rejected);

   function Conflict (Status : Recovery_Result_Status) return Boolean is
     (Status = Conflict);

   function Operational (Status : Recovery_Result_Status) return Boolean is
     (Status = Operational_Failure);
end Identity.Recovery.Results;
