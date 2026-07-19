package Identity.Errors.Retry is
   pragma Pure;

   function Retryable (Value : Identity.Errors.Retry_Class) return Boolean is
     (Value in Identity.Errors.Retry_Same_Request | Identity.Errors.Retry_After);
end Identity.Errors.Retry;
