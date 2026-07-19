with Identity.Policies.Snapshots;
with Identity.Services.Contexts;

package Identity.Services.Construction is
   pragma Pure;

   function Build
     (Policy : Identity.Policies.Snapshots.Policy_Snapshot;
      Deterministic_Test : Boolean := False)
      return Identity.Services.Contexts.Service_Context;
end Identity.Services.Construction;
