package Identity.Contracts is
   pragma Pure;

   type Contract_Status is (Satisfied, Violated);

   function Require (Condition : Boolean) return Contract_Status is
     (if Condition then Satisfied else Violated);

   function Satisfied_Status (Status : Contract_Status) return Boolean is
     (Status = Satisfied);
   function Violated_Status (Status : Contract_Status) return Boolean is
     (Status = Violated);
   function Rejected (Status : Contract_Status) return Boolean is
     (Status = Violated);
end Identity.Contracts;
