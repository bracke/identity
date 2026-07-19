with Identity.Text.Bounded;
with Identity.Versions;

package Identity.Codecs.Persisted is
   pragma Pure;

   type Version_Window is record
      Current : Identity.Versions.Format_Version := 1;
      Minimum : Identity.Versions.Format_Version := 1;
      Maximum : Identity.Versions.Format_Version := 1;
   end record;

   type Canonical_Admission is record
      Window_Valid      : Boolean := False;
      Version_Supported : Boolean := False;
      Canonical         : Boolean := False;
      Status            : Identity.Codecs.Codec_Status := Identity.Codecs.Invalid;
   end record;

   function Validate_Window (Value : Version_Window) return Identity.Codecs.Codec_Status;
   function Validate_Format
     (Version : Identity.Versions.Format_Version;
      Window  : Version_Window) return Identity.Codecs.Codec_Status;
   function Validate_Canonical
     (Value   : Identity.Text.Bounded.Bounded_Text;
      Version : Identity.Versions.Format_Version;
      Window  : Version_Window) return Identity.Codecs.Codec_Status;
   function Admit_Canonical
     (Value   : Identity.Text.Bounded.Bounded_Text;
      Version : Identity.Versions.Format_Version;
      Window  : Version_Window) return Canonical_Admission;
end Identity.Codecs.Persisted;
