with Identity.Crypto.Password_Hashing;

package Identity.Passwords.Migrations is
   type Migration_Mode is
     (Defer,
      Require,
      Restrict_Session_Issuance,
      Fail_If_Mandatory_Cannot_Complete);

   type Migration_Decision is
     (No_Migration,
      Migration_Recommended,
      Migration_Required,
      Authentication_Restricted,
      Operational_Failure);

   function Authentication_May_Proceed
     (Decision : Migration_Decision) return Boolean is
     (Decision /= Operational_Failure);

   function Migration_Not_Needed
     (Decision : Migration_Decision) return Boolean is
     (Decision = No_Migration);

   function Migration_Should_Be_Attempted
     (Decision : Migration_Decision) return Boolean is
     (Decision in Migration_Recommended | Migration_Required);

   function Migration_Is_Mandatory
     (Decision : Migration_Decision) return Boolean is
     (Decision = Migration_Required);

   function Session_Issuance_Restricted
     (Decision : Migration_Decision) return Boolean is
     (Decision = Authentication_Restricted);

   function Operational
     (Decision : Migration_Decision) return Boolean is
     (Decision = Operational_Failure);

   function Decide
     (Status : Identity.Crypto.Password_Hashing.Migration_Status;
      Mode   : Migration_Mode) return Migration_Decision;
end Identity.Passwords.Migrations;
