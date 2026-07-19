package Identity.Internal.Encoding is
   pragma Pure;

   type Encoding_Purpose is
     (Canonical_Event,
      Persisted_Verifier,
      Token_Input,
      Subject_Fingerprint_Input,
      External_Assertion_Fingerprint_Input);

   type Encoding_Status is (Encoded, Malformed, Too_Large, Unsupported_Version);
end Identity.Internal.Encoding;
