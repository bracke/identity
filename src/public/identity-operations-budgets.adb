package body Identity.Operations.Budgets is
   function Within
     (Requested : Operation_Budget;
      Limits    : Operation_Budget) return Boolean is
     (Admit (Requested, Limits).Status = Within_Limits);

   function Rejected
     (Dimension : Budget_Dimension;
      Requested : Natural;
      Limit     : Natural) return Budget_Admission is
     ((Status => Limit_Exceeded,
       Dimension => Dimension,
       Requested => Requested,
       Limit => Limit));

   function Admit
     (Requested : Operation_Budget;
      Limits    : Operation_Budget) return Budget_Admission is
   begin
      if Requested.Repository_Reads > Limits.Repository_Reads then
         return Rejected
           (Repository_Reads, Requested.Repository_Reads, Limits.Repository_Reads);
      elsif Requested.Repository_Writes > Limits.Repository_Writes then
         return Rejected
           (Repository_Writes, Requested.Repository_Writes, Limits.Repository_Writes);
      elsif Requested.Entities_Loaded > Limits.Entities_Loaded then
         return Rejected
           (Entities_Loaded, Requested.Entities_Loaded, Limits.Entities_Loaded);
      elsif Requested.Cryptographic_Operations > Limits.Cryptographic_Operations then
         return Rejected
           (Cryptographic_Operations,
            Requested.Cryptographic_Operations,
            Limits.Cryptographic_Operations);
      elsif Requested.Password_History_Checks > Limits.Password_History_Checks then
         return Rejected
           (Password_History_Checks,
            Requested.Password_History_Checks,
            Limits.Password_History_Checks);
      elsif Requested.Factor_Challenges > Limits.Factor_Challenges then
         return Rejected
           (Factor_Challenges, Requested.Factor_Challenges, Limits.Factor_Challenges);
      elsif Requested.Events > Limits.Events then
         return Rejected (Events, Requested.Events, Limits.Events);
      elsif Requested.Event_Attributes > Limits.Event_Attributes then
         return Rejected
           (Event_Attributes, Requested.Event_Attributes, Limits.Event_Attributes);
      elsif Requested.Collection_Capacity > Limits.Collection_Capacity then
         return Rejected
           (Collection_Capacity,
            Requested.Collection_Capacity,
            Limits.Collection_Capacity);
      elsif Requested.Retry_Count > Limits.Retry_Count then
         return Rejected (Retry_Count, Requested.Retry_Count, Limits.Retry_Count);
      elsif Requested.Input_Bytes > Limits.Input_Bytes then
         return Rejected (Input_Bytes, Requested.Input_Bytes, Limits.Input_Bytes);
      elsif Requested.Output_Bytes > Limits.Output_Bytes then
         return Rejected (Output_Bytes, Requested.Output_Bytes, Limits.Output_Bytes);
      else
         return
           (Status => Within_Limits,
            Dimension => Repository_Reads,
            Requested => 0,
            Limit => 0);
      end if;
   end Admit;
end Identity.Operations.Budgets;
