with Identity.Identifiers.Entities;
with Identity.Tokens.Definitions;
with Identity.Tokens.Verification;
with Identity.Versions;

package Identity.Adapters.Repositories.Tokens is
   pragma Pure;

   type Token_Read_Status is (Found, Not_Found, Expired, Consumed, Revoked, Capacity_Exceeded, Infrastructure_Failure);

   function Found_Status (Status : Token_Read_Status) return Boolean is
     (Status = Found);

   function Missing_Status (Status : Token_Read_Status) return Boolean is
     (Status = Not_Found);

   function Expired_Status (Status : Token_Read_Status) return Boolean is
     (Status = Expired);

   function Consumed_Status (Status : Token_Read_Status) return Boolean is
     (Status = Consumed);

   function Revoked_Status (Status : Token_Read_Status) return Boolean is
     (Status = Revoked);

   function Capacity_Rejected (Status : Token_Read_Status) return Boolean is
     (Status = Capacity_Exceeded);

   function Infrastructure_Failed (Status : Token_Read_Status) return Boolean is
     (Status = Infrastructure_Failure);

   function Operational_Failure (Status : Token_Read_Status) return Boolean is
     (Status in Capacity_Exceeded | Infrastructure_Failure);

   function Terminal_Rejection (Status : Token_Read_Status) return Boolean is
     (Status in Not_Found | Expired | Consumed | Revoked);

   type Token_View is record
      Status   : Token_Read_Status := Not_Found;
      Token_Id : Identity.Identifiers.Entities.Token_Id;
      Token    : Identity.Tokens.Definitions.Action_Token_Record;
      Outcome  : Identity.Tokens.Verification.Token_Verification_Outcome :=
        Identity.Tokens.Verification.Unknown;
      Version  : Identity.Versions.Entity_Version := 0;
   end record;
end Identity.Adapters.Repositories.Tokens;
