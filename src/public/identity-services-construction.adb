package body Identity.Services.Construction is
   function Build
     (Policy : Identity.Policies.Snapshots.Policy_Snapshot;
      Deterministic_Test : Boolean := False)
      return Identity.Services.Contexts.Service_Context is
     ((Capabilities =>
         (Repository_Security_Transitions => True,
          Atomic_Mandatory_Events => True,
          Cryptolib_Backend => True,
          Deterministic_Test_Construction => Deterministic_Test,
          Concurrent_Safe_Adapters => False),
       Policy => Policy,
       Resource_Limits => Policy.Budget));
end Identity.Services.Construction;
