with Identity.Limits;

package body Identity.Operations.Sessions.Purge_Retained is
   use type Identity.Times.Instant;

   Seconds_Per_Day : constant Identity.Times.Instant := 86_400;

   function Retention_Boundary
     (Now    : Identity.Times.Instant;
      Policy : Identity.Policies.Snapshots.Session_Policy;
      Ok     : out Boolean) return Identity.Times.Instant
   is
      Span : Identity.Times.Instant;
   begin
      if Policy.Maximum_Retention_Days > Identity.Limits.Max_Session_Retention_Days then
         Ok := False;
         return Identity.Times.Instant'First;
      end if;

      Span := Identity.Times.Instant (Policy.Maximum_Retention_Days) * Seconds_Per_Day;

      if Now < Identity.Times.Instant'First + Span then
         Ok := False;
         return Identity.Times.Instant'First;
      end if;

      Ok := True;
      return Now - Span;
   end Retention_Boundary;

   function Execute
     (Repository   : in out Identity.Adapters.Repositories.Memory.Store;
      Retain_After : Identity.Times.Instant) return Natural is
   begin
      return Identity.Adapters.Repositories.Memory.Purge_Retained_Sessions
        (Repository, Retain_After);
   end Execute;
end Identity.Operations.Sessions.Purge_Retained;
