with Identity.Codecs.Canonical;

package body Identity.Codecs.Persisted is
   use type Identity.Versions.Format_Version;

   function Validate_Window (Value : Version_Window) return Identity.Codecs.Codec_Status is
   begin
      if Value.Minimum > Value.Current or else Value.Current > Value.Maximum then
         return Identity.Codecs.Invalid;
      end if;

      return Identity.Codecs.Valid;
   end Validate_Window;

   function Validate_Format
     (Version : Identity.Versions.Format_Version;
      Window  : Version_Window) return Identity.Codecs.Codec_Status
   is
   begin
      if Validate_Window (Window) /= Identity.Codecs.Valid then
         return Identity.Codecs.Invalid;
      end if;

      if Version < Window.Minimum or else Version > Window.Maximum then
         return Identity.Codecs.Unsupported_Version;
      end if;

      return Identity.Codecs.Valid;
   end Validate_Format;

   function Validate_Canonical
     (Value   : Identity.Text.Bounded.Bounded_Text;
      Version : Identity.Versions.Format_Version;
      Window  : Version_Window) return Identity.Codecs.Codec_Status
   is
      Version_Status : constant Identity.Codecs.Codec_Status :=
        Validate_Format (Version, Window);
   begin
      if Version_Status /= Identity.Codecs.Valid then
         return Version_Status;
      end if;

      if not Identity.Codecs.Canonical.Is_Canonical_Frame (Value) then
         return Identity.Codecs.Noncanonical;
      end if;

      return Identity.Codecs.Valid;
   end Validate_Canonical;

   function Admit_Canonical
     (Value   : Identity.Text.Bounded.Bounded_Text;
      Version : Identity.Versions.Format_Version;
      Window  : Version_Window) return Canonical_Admission
   is
      Window_Status : constant Identity.Codecs.Codec_Status := Validate_Window (Window);
      Format_Status : Identity.Codecs.Codec_Status := Identity.Codecs.Invalid;
      Canonical     : Boolean := False;
   begin
      if Window_Status /= Identity.Codecs.Valid then
         return
           (Window_Valid => False,
            Version_Supported => False,
            Canonical => False,
            Status => Window_Status);
      end if;

      Format_Status := Validate_Format (Version, Window);
      if Format_Status /= Identity.Codecs.Valid then
         return
           (Window_Valid => True,
            Version_Supported => False,
            Canonical => False,
            Status => Format_Status);
      end if;

      Canonical := Identity.Codecs.Canonical.Is_Canonical_Frame (Value);
      return
        (Window_Valid => True,
         Version_Supported => True,
         Canonical => Canonical,
         Status =>
           (if Canonical then Identity.Codecs.Valid else Identity.Codecs.Noncanonical));
   end Admit_Canonical;
end Identity.Codecs.Persisted;
