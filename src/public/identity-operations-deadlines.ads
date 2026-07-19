with Identity.Times;

package Identity.Operations.Deadlines is
   pragma Pure;

   function None return Identity.Times.Deadline is
     ((Present => False, Time_Point => 0));

   function At_Time (Time_Point : Identity.Times.Instant) return Identity.Times.Deadline is
     ((Present => True, Time_Point => Time_Point));
end Identity.Operations.Deadlines;
