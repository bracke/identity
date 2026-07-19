package body Identity.Errors.Public is

   function Code_For
     (Value : Identity.Errors.Error_Value)
      return Identity.Identifiers.Registry.Registry_Id
   is
   begin
      case Value.Category is
         when Identity.Errors.Success =>
            return Identity.Errors.Codes.Authentication_Rejected;
         when Identity.Errors.Rejection
            | Identity.Errors.Additional_Action_Required =>
            return Identity.Errors.Codes.Authentication_Rejected;
         when Identity.Errors.Conflict =>
            return Identity.Errors.Codes.Version_Conflict;
         when Identity.Errors.Invalid_Input =>
            return Identity.Errors.Codes.Authentication_Rejected;
         when Identity.Errors.Unsupported
            | Identity.Errors.Operational_Failure
            | Identity.Errors.Resource_Limit
            | Identity.Errors.Internal_Invariant_Failure =>
            case Value.Cause is
               when Identity.Errors.Cryptographic_Service =>
                  return Identity.Errors.Codes.Crypto_Unavailable;
               when Identity.Errors.Repository =>
                  return Identity.Errors.Codes.Repository_Unavailable;
               when others =>
                  return Identity.Errors.Codes.Authentication_Rejected;
            end case;
      end case;
   end Code_For;

   function To_Public
     (Value : Identity.Errors.Error_Value;
      Include_Diagnostic : Boolean := False) return Public_Error_Projection
   is
   begin
      return
        (Category => Value.Category,
         Code => Code_For (Value),
         Message => Identity.Errors.Messages.Message_For (Value.Category),
         Retry => Value.Retry,
         Cause => Value.Cause,
         Operation_Set => Value.Operation_Set,
         Correlation_Set => Value.Correlation_Set,
         Diagnostic_Allowed =>
           Include_Diagnostic
           and then Value.Category in
             Identity.Errors.Operational_Failure
             | Identity.Errors.Internal_Invariant_Failure);
   end To_Public;

end Identity.Errors.Public;
