package Identity.Services.Capabilities is
   pragma Pure;

   type Capability_Set is record
      Repository_Security_Transitions : Boolean := True;
      Atomic_Mandatory_Events         : Boolean := True;
      Cryptolib_Backend               : Boolean := True;
      Deterministic_Test_Construction : Boolean := False;
      Concurrent_Safe_Adapters        : Boolean := False;
   end record;

   function Production_Ready (Capabilities : Capability_Set) return Boolean is
     (Capabilities.Repository_Security_Transitions
      and then Capabilities.Atomic_Mandatory_Events
      and then Capabilities.Cryptolib_Backend);
end Identity.Services.Capabilities;
