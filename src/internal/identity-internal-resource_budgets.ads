package Identity.Internal.Resource_Budgets is
   pragma Pure;

   type Budget_Dimension is
     (Repository_Reads,
      Repository_Writes,
      Entities_Loaded,
      Cryptographic_Operations,
      Password_History_Checks,
      Factor_Challenges,
      Events,
      Event_Attributes,
      Retry_Count,
      Input_Size,
      Output_Size);

   type Budget_Status is (Within_Limit, Exhausted, Hard_Limit_Exceeded);
end Identity.Internal.Resource_Budgets;
