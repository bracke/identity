with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Text_IO;

package body Identity_Tools_Crypto_Validation is

   type Algorithm_Id is
     (Password_PBKDF2_HMAC_SHA256,
      SHA256_Domain_Verifier);

   type Descriptor_Field_Id is
     (Password_Hashing_Class,
      Secret_Verifier_Class,
      Cryptolib_Implementation,
      Format_Version_One,
      Constant_Time_Verification,
      Creation_Allowed,
      Verification_Allowed,
      Not_Deprecated);

   type Algorithm_Presence is array (Algorithm_Id) of Boolean;
   type Field_Presence is array (Descriptor_Field_Id) of Boolean;

   Expected_Algorithm_Count : constant Natural :=
     Algorithm_Id'Pos (Algorithm_Id'Last) + 1;

   function Contains (Line : String; Pattern : String) return Boolean is
     (Ada.Strings.Fixed.Index (Line, Pattern) /= 0);

   function Registry_Path return String is
     (if Ada.Directories.Exists ("registries/crypto-algorithms.json") then
        "registries/crypto-algorithms.json"
      else
        "../../registries/crypto-algorithms.json");

   function Image (Id : Algorithm_Id) return String is
     (case Id is
        when Password_PBKDF2_HMAC_SHA256 => "identity.pbkdf2-hmac-sha256",
        when SHA256_Domain_Verifier => "identity.sha256-domain-verifier");

   function Image (Id : Descriptor_Field_Id) return String is
     (case Id is
        when Password_Hashing_Class => """class"": ""password-hashing""",
        when Secret_Verifier_Class => """class"": ""secret-verifier""",
        when Cryptolib_Implementation => """implementation"": ""cryptolib""",
        when Format_Version_One => """format_versions"": [1]",
        when Constant_Time_Verification =>
          """constant_time_verification"": true",
        when Creation_Allowed => """creation_allowed"": true",
        when Verification_Allowed => """verification_allowed"": true",
        when Not_Deprecated => """deprecated"": false");

   procedure Count_Field
     (Id       : Descriptor_Field_Id;
      Presence : in out Field_Presence;
      Report   : in out Validation_Report)
   is
   begin
      case Id is
         when Password_Hashing_Class | Secret_Verifier_Class =>
            Report.Class_Count := Report.Class_Count + 1;
         when Cryptolib_Implementation =>
            Report.Implementation_Count := Report.Implementation_Count + 1;
         when Format_Version_One =>
            Report.Format_Version_Count := Report.Format_Version_Count + 1;
         when Constant_Time_Verification =>
            Report.Constant_Time_Count := Report.Constant_Time_Count + 1;
         when Creation_Allowed =>
            Report.Creation_Count := Report.Creation_Count + 1;
         when Verification_Allowed =>
            Report.Verify_Count := Report.Verify_Count + 1;
         when Not_Deprecated =>
            Report.Deprecated_State_Count := Report.Deprecated_State_Count + 1;
      end case;

      Presence (Id) := True;
   end Count_Field;

   procedure Validate (Report : out Validation_Report) is
      File       : Ada.Text_IO.File_Type;
      Algorithms : Algorithm_Presence := [others => False];
      Fields     : Field_Presence := [others => False];
   begin
      Report := (others => 0);

      if not Ada.Directories.Exists (Registry_Path) then
         Ada.Text_IO.Put_Line
           ("crypto-algorithms:missing-registry:" & Registry_Path);
         return;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Registry_Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (File);
         begin
            for Id in Algorithm_Id loop
               if Contains (Line, """" & Image (Id) & """") then
                  if not Algorithms (Id) then
                     Report.Algorithm_Count := Report.Algorithm_Count + 1;
                  end if;
                  Algorithms (Id) := True;
               end if;
            end loop;

            for Id in Descriptor_Field_Id loop
               if Contains (Line, Image (Id)) then
                  Count_Field (Id, Fields, Report);
               end if;
            end loop;
         end;
      end loop;
      Ada.Text_IO.Close (File);

      for Id in Algorithm_Id loop
         if not Algorithms (Id) then
            Report.Missing_Algorithms := Report.Missing_Algorithms + 1;
            Ada.Text_IO.Put_Line
              ("crypto-algorithms:missing-algorithm:" & Image (Id));
         end if;
      end loop;

      for Id in Descriptor_Field_Id loop
         if not Fields (Id) then
            Report.Missing_Descriptor_Fields :=
              Report.Missing_Descriptor_Fields + 1;
            Ada.Text_IO.Put_Line
              ("crypto-algorithms:missing-field:" & Image (Id));
         end if;
      end loop;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Validate;

   function Passed (Report : Validation_Report) return Boolean is
     (Report.Algorithm_Count = Expected_Algorithm_Count
      and then Report.Class_Count = 2
      and then Report.Implementation_Count = Expected_Algorithm_Count
      and then Report.Format_Version_Count = Expected_Algorithm_Count
      and then Report.Constant_Time_Count = Expected_Algorithm_Count
      and then Report.Creation_Count = Expected_Algorithm_Count
      and then Report.Verify_Count = Expected_Algorithm_Count
      and then Report.Deprecated_State_Count = Expected_Algorithm_Count
      and then Report.Missing_Algorithms = 0
      and then Report.Missing_Descriptor_Fields = 0);

end Identity_Tools_Crypto_Validation;
