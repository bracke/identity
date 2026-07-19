package Identity.Codecs is
   pragma Pure;

   type Codec_Status is
     (Valid,
      Invalid,
      Too_Large,
      Unsupported_Version,
      Noncanonical);

   function Accepted (Status : Codec_Status) return Boolean is
     (Status = Valid);

   function Malformed (Status : Codec_Status) return Boolean is
     (Status = Invalid);

   function Oversized (Status : Codec_Status) return Boolean is
     (Status = Too_Large);

   function Version_Unsupported (Status : Codec_Status) return Boolean is
     (Status = Unsupported_Version);

   function Noncanonical_Rejected (Status : Codec_Status) return Boolean is
     (Status = Noncanonical);

   function Decoder_Rejected (Status : Codec_Status) return Boolean is
     (Status in Invalid | Too_Large | Unsupported_Version | Noncanonical);
end Identity.Codecs;
