with Identity.Policies.Snapshots;
with Identity.Services.Capabilities;

package Identity.Services.Contexts is
   pragma Pure;

   type Service_Context is record
      Capabilities : Identity.Services.Capabilities.Capability_Set;
      Policy       : Identity.Policies.Snapshots.Policy_Snapshot;
      Resource_Limits : Identity.Policies.Snapshots.Resource_Budget;
   end record;

   function Is_Usable (Context : Service_Context) return Boolean;
end Identity.Services.Contexts;
