with Identity.Identifiers.Entities;
with Identity.Limits;
with Identity.Text.Bounded;

package Identity.Tokens.Generation is
   pragma Pure;

   type Presented_Token_Status is
     (Accepted,
      Empty_Input,
      Too_Large,
      Missing_Separator,
      Multiple_Separators,
      Missing_Public_Part,
      Missing_Secret_Part);

   type Presented_Token (Status : Presented_Token_Status := Empty_Input) is record
      case Status is
         when Accepted =>
            Public_Part : Identity.Text.Bounded.Bounded_Text;
            Secret_Part : Identity.Text.Bounded.Bounded_Text;
         when Empty_Input
            | Too_Large
            | Missing_Separator
            | Multiple_Separators
            | Missing_Public_Part
            | Missing_Secret_Part =>
            null;
      end case;
   end record;

   type Split_Token is record
      Public_Id : Identity.Identifiers.Entities.Token_Id;
      Encoded_Public_Part : Identity.Text.Bounded.Bounded_Text;
      Secret_Returned_Once : Boolean := True;
   end record;

   function Safe_To_Return (Value : Split_Token) return Boolean is
     (Value.Secret_Returned_Once);

   function Accepted_Input (Status : Presented_Token_Status) return Boolean is
     (Status = Accepted);

   function Rejected_Input (Status : Presented_Token_Status) return Boolean is
     (Status /= Accepted);

   function Empty_Rejection (Status : Presented_Token_Status) return Boolean is
     (Status = Empty_Input);

   function Size_Rejection (Status : Presented_Token_Status) return Boolean is
     (Status = Too_Large);

   function Structural_Rejection (Status : Presented_Token_Status) return Boolean is
     (Status in Missing_Separator | Multiple_Separators | Missing_Public_Part
              | Missing_Secret_Part);

   function Public_Part_Rejection (Status : Presented_Token_Status) return Boolean is
     (Status = Missing_Public_Part);

   function Secret_Part_Rejection (Status : Presented_Token_Status) return Boolean is
     (Status = Missing_Secret_Part);

   function Parse
     (Value     : String;
      Separator : Character := '.') return Presented_Token
     with Pre => Value'Length <= Identity.Limits.Max_Input_Bytes;
end Identity.Tokens.Generation;
