with Identity.Errors.Codes;
with Identity.Errors.Messages;
with Identity.Identifiers.Registry;

package Identity.Errors.Public is
   type Public_Error_Projection is record
      Category        : Identity.Errors.Error_Category := Identity.Errors.Success;
      Code            : Identity.Identifiers.Registry.Registry_Id :=
        Identity.Errors.Codes.Authentication_Rejected;
      Message         : Identity.Identifiers.Registry.Registry_Id :=
        Identity.Errors.Messages.Message_For (Identity.Errors.Success);
      Retry           : Identity.Errors.Retry_Class := Identity.Errors.Do_Not_Retry;
      Cause           : Identity.Errors.Cause_Class := Identity.Errors.Caller_Input;
      Operation_Set   : Boolean := False;
      Correlation_Set : Boolean := False;
      Diagnostic_Allowed : Boolean := False;
   end record;

   function Code_For
     (Value : Identity.Errors.Error_Value)
      return Identity.Identifiers.Registry.Registry_Id;

   function To_Public
     (Value : Identity.Errors.Error_Value;
      Include_Diagnostic : Boolean := False) return Public_Error_Projection;

   function Diagnostic_Disclosure_Allowed
     (Value : Public_Error_Projection) return Boolean is
     (Value.Diagnostic_Allowed
      and then Value.Category in
        Identity.Errors.Operational_Failure
        | Identity.Errors.Internal_Invariant_Failure);

   function Retryable
     (Value : Public_Error_Projection) return Boolean is
     (Value.Retry /= Identity.Errors.Do_Not_Retry);

   function Operational
     (Value : Public_Error_Projection) return Boolean is
     (Value.Category in
        Identity.Errors.Operational_Failure
        | Identity.Errors.Resource_Limit
        | Identity.Errors.Internal_Invariant_Failure);

   function Generic_Authentication_Rejection
     (Value : Public_Error_Projection) return Boolean is
     (Identity.Identifiers.Registry.Image (Value.Code)
      = Identity.Identifiers.Registry.Image (Identity.Errors.Codes.Authentication_Rejected));

   function Repository_Unavailable
     (Value : Public_Error_Projection) return Boolean is
     (Identity.Identifiers.Registry.Image (Value.Code)
      = Identity.Identifiers.Registry.Image (Identity.Errors.Codes.Repository_Unavailable));

   function Crypto_Unavailable
     (Value : Public_Error_Projection) return Boolean is
     (Identity.Identifiers.Registry.Image (Value.Code)
      = Identity.Identifiers.Registry.Image (Identity.Errors.Codes.Crypto_Unavailable));

   function Dependency_Unavailable
     (Value : Public_Error_Projection) return Boolean is
     (Repository_Unavailable (Value) or else Crypto_Unavailable (Value));
end Identity.Errors.Public;
