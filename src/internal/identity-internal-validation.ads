package Identity.Internal.Validation is
   pragma Pure;

   type Validation_Target is
     (Public_Input,
      Policy_Snapshot,
      Repository_Capabilities,
      Persisted_Envelope,
      Canonical_Encoding);

   type Validation_Status is (Valid, Invalid_Input, Unsupported, Resource_Limit, Invariant_Breach);
end Identity.Internal.Validation;
