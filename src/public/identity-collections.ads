package Identity.Collections is
   pragma Pure;

   type Collection_Status is
     (Ok,
      Full,
      Duplicate,
      Missing,
      Invalid_Index);

   subtype Collection_Count is Natural;

   function Successful (Status : Collection_Status) return Boolean is
     (Status = Ok);

   function Capacity_Exhausted (Status : Collection_Status) return Boolean is
     (Status = Full);

   function Duplicate_Rejected (Status : Collection_Status) return Boolean is
     (Status = Duplicate);

   function Missing_Rejected (Status : Collection_Status) return Boolean is
     (Status = Missing);

   function Invalid_Index_Rejected (Status : Collection_Status) return Boolean is
     (Status = Invalid_Index);

   function No_Mutation (Status : Collection_Status) return Boolean is
     (Status in Full | Duplicate | Missing | Invalid_Index);
end Identity.Collections;
