with Identity.Policies.Snapshots;

package Identity.Policies.Providers is
   pragma Pure;

   type Static_Policy_Provider is record
      Snapshot : Identity.Policies.Snapshots.Policy_Snapshot;
   end record;

   function Current
     (Provider : Static_Policy_Provider)
      return Identity.Policies.Snapshots.Policy_Snapshot;
end Identity.Policies.Providers;
