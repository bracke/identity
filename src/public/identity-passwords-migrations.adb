package body Identity.Passwords.Migrations is
   function Decide
     (Status : Identity.Crypto.Password_Hashing.Migration_Status;
      Mode   : Migration_Mode) return Migration_Decision
   is
   begin
      case Status is
         when Identity.Crypto.Password_Hashing.Current =>
            return No_Migration;
         when Identity.Crypto.Password_Hashing.Upgrade_Recommended =>
            if Mode = Restrict_Session_Issuance then
               return Authentication_Restricted;
            else
               return Migration_Recommended;
            end if;
         when Identity.Crypto.Password_Hashing.Upgrade_Required =>
            case Mode is
               when Defer =>
                  return Migration_Required;
               when Require =>
                  return Migration_Required;
               when Restrict_Session_Issuance =>
                  return Authentication_Restricted;
               when Fail_If_Mandatory_Cannot_Complete =>
                  return Operational_Failure;
            end case;
      end case;
   end Decide;
end Identity.Passwords.Migrations;
