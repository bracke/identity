package body Identity.Policies.Providers is
   function Current
     (Provider : Static_Policy_Provider)
      return Identity.Policies.Snapshots.Policy_Snapshot is
     (Provider.Snapshot);
end Identity.Policies.Providers;
