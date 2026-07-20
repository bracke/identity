with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Text_IO;

package body Identity_Tools_Proof_Validation is

   type Package_Id is
     (Collections,
      Text_Bounded,
      Times_Expirations,
      Versions,
      Codecs_Canonical,
      Tokens_Definitions,
      Sessions_Rotation,
      Secrets_One_Time,
      Operations_Contexts,
      Recovery_Code_Sets,
      Crypto_Password_Hashing);

   type Property_Id is
     (Collection_Bounds,
      Identifier_And_Text_Length_Invariants,
      Time_Arithmetic_Overflow,
      Counter_Saturation,
      Canonical_Encoding_Bounds,
      Token_State_Transitions,
      Session_Rotation_Generation,
      One_Time_Secret_State,
      Option_And_Result_Variant_Safety,
      Selected_State_Machine_Invariants);

   type Package_Presence is array (Package_Id) of Boolean;
   type Property_Presence is array (Property_Id) of Boolean;

   Expected_Package_Count : constant Natural :=
     Package_Id'Pos (Package_Id'Last) + 1;
   Expected_Property_Count : constant Natural :=
     Property_Id'Pos (Property_Id'Last) + 1;

   function Contains (Line : String; Pattern : String) return Boolean is
     (Ada.Strings.Fixed.Index (Line, Pattern) /= 0);

   function Registry_Path return String is
     (if Ada.Directories.Exists ("registries/proof-" & "sco" & "pe.json") then
        "registries/proof-" & "sco" & "pe.json"
      else
        "../../registries/proof-" & "sco" & "pe.json");

   function Image (Id : Package_Id) return String is
     (case Id is
        when Collections => "Identity.Collections",
        when Text_Bounded => "Identity.Text.Bounded",
        when Times_Expirations => "Identity.Times.Expirations",
        when Versions => "Identity.Versions",
        when Codecs_Canonical => "Identity.Codecs.Canonical",
        when Tokens_Definitions => "Identity.Tokens.Definitions",
        when Sessions_Rotation => "Identity.Sessions.Rotation",
        when Secrets_One_Time => "Identity.Secrets.One_Time",
        when Operations_Contexts => "Identity.Operations.Contexts",
        when Recovery_Code_Sets => "Identity.Recovery_Codes.Sets",
        when Crypto_Password_Hashing => "Identity.Crypto.Password_Hashing");

   function Image (Id : Property_Id) return String is
     (case Id is
        when Collection_Bounds => "collection-bounds",
        when Identifier_And_Text_Length_Invariants =>
          "identifier-and-text-length-invariants",
        when Time_Arithmetic_Overflow => "time-arithmetic-overflow",
        when Counter_Saturation => "counter-saturation",
        when Canonical_Encoding_Bounds => "canonical-encoding-bounds",
        when Token_State_Transitions => "token-state-transitions",
        when Session_Rotation_Generation => "session-rotation-generation",
        when One_Time_Secret_State => "one-time-secret-state",
        when Option_And_Result_Variant_Safety =>
          "option-and-result-variant-safety",
        when Selected_State_Machine_Invariants =>
          "selected-state-machine-invariants");

   procedure Validate (Report : out Validation_Report) is
      File       : Ada.Text_IO.File_Type;
      Packages   : Package_Presence := [others => False];
      Properties : Property_Presence := [others => False];
   begin
      Report := (others => 0);
      Report.Missing_Gate := 1;
      Report.Missing_Orchestrator := 1;
      Report.Missing_Baseline_Rule := 1;

      if not Ada.Directories.Exists (Registry_Path) then
         Ada.Text_IO.Put_Line ("proof-validation:missing-registry:" & Registry_Path);
         return;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Registry_Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (File);
         begin
            if Contains (Line, """gate"": ""gnatprove""") then
               Report.Missing_Gate := 0;
            end if;

            if Contains (Line, """orchestrator"": ""project_tools""") then
               Report.Missing_Orchestrator := 0;
            end if;

            if Contains (Line, """may_lower_baseline_silently"": false") then
               Report.Missing_Baseline_Rule := 0;
            end if;

            if Contains (Line, """excluded"": true") then
               Report.Exclusion_Count := Report.Exclusion_Count + 1;
            end if;

            if Contains (Line, """exclusion_reason"": """)
              and then not Contains (Line, """exclusion_reason"": """"")
            then
               Report.Exclusion_Reasons := Report.Exclusion_Reasons + 1;
            end if;

            if Contains (Line, """compensating_tests"": []") then
               Report.Empty_Compensations := Report.Empty_Compensations + 1;
            end if;

            for Id in Package_Id loop
               if Contains (Line, """" & Image (Id) & """") then
                  if not Packages (Id) then
                     Report.Package_Count := Report.Package_Count + 1;
                  end if;
                  Packages (Id) := True;
               end if;
            end loop;

            for Id in Property_Id loop
               if Contains (Line, """" & Image (Id) & """") then
                  if not Properties (Id) then
                     Report.Property_Count := Report.Property_Count + 1;
                  end if;
                  Properties (Id) := True;
               end if;
            end loop;
         end;
      end loop;
      Ada.Text_IO.Close (File);

      for Id in Package_Id loop
         if not Packages (Id) then
            Report.Missing_Packages := Report.Missing_Packages + 1;
            Ada.Text_IO.Put_Line ("proof-validation:missing-package:" & Image (Id));
         end if;
      end loop;

      for Id in Property_Id loop
         if not Properties (Id) then
            Report.Missing_Properties := Report.Missing_Properties + 1;
            Ada.Text_IO.Put_Line ("proof-validation:missing-property:" & Image (Id));
         end if;
      end loop;

      if Report.Missing_Gate /= 0 then
         Ada.Text_IO.Put_Line ("proof-validation:missing-gate:gnatprove");
      end if;

      if Report.Missing_Orchestrator /= 0 then
         Ada.Text_IO.Put_Line ("proof-validation:missing-orchestrator:project_tools");
      end if;

      if Report.Missing_Baseline_Rule /= 0 then
         Ada.Text_IO.Put_Line ("proof-validation:missing-baseline-rule");
      end if;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Validate;

   function Passed (Report : Validation_Report) return Boolean is
     (Report.Package_Count = Expected_Package_Count
      and then Report.Property_Count = Expected_Property_Count
      and then Report.Exclusion_Reasons = Report.Exclusion_Count
      and then Report.Empty_Compensations = 0
      and then Report.Missing_Packages = 0
      and then Report.Missing_Properties = 0
      and then Report.Missing_Gate = 0
      and then Report.Missing_Orchestrator = 0
      and then Report.Missing_Baseline_Rule = 0);

end Identity_Tools_Proof_Validation;
