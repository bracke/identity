with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Text_IO;

package body Identity_Tools_Architecture is
   use type Ada.Directories.File_Kind;

   function Contains (Line : String; Pattern : String) return Boolean is
     (Ada.Strings.Fixed.Index (Line, Pattern) /= 0);

   function Is_Ada_Source (Path : String) return Boolean is
     (Path'Length >= 4
      and then (Path (Path'Last - 3 .. Path'Last) = ".ads"
                or else Path (Path'Last - 3 .. Path'Last) = ".adb"));

   --  Direct cryptolib imports are confined to the Identity.Crypto.CryptoLib.*
   --  isolation subtree; any body under that prefix may bind cryptolib, and
   --  nothing outside it may.
   function Is_Approved_Crypto_File (Path : String) return Boolean is
     (Contains (Path, "src/public/identity-crypto-cryptolib-")
      and then Path'Length >= 4
      and then Path (Path'Last - 3 .. Path'Last) = ".adb");

   function Has_Boundary_Term (Line : String) return Boolean is
     (Contains (Line, "ro" & "le")
      or else Contains (Line, "per" & "mission")
      or else Contains (Line, "ten" & "ant")
      or else Contains (Line, "dele" & "gation")
      or else Contains (Line, "imper" & "sonation")
      or else Contains (Line, "over" & "ride")
      or else Contains (Line, "obli" & "gation")
      or else Contains (Line, "sco" & "pe")
      or else Contains (Line, "enforce" & "ment"));

   procedure Check_Line
     (Path   : String;
      Line   : String;
      Report : in out Validation_Report)
   is
   begin
      if Contains (Line, "Identity." & "Internal") then
         Report.Internal_Dependency_Hits := Report.Internal_Dependency_Hits + 1;
         Ada.Text_IO.Put_Line ("architecture:internal-dependency:" & Path);
      end if;

      if Contains (Line, "with Crypto" & "Lib") then
         Report.Crypto_Import_Hits := Report.Crypto_Import_Hits + 1;
         if not Is_Approved_Crypto_File (Path) then
            Report.Crypto_Import_Violations := Report.Crypto_Import_Violations + 1;
            Ada.Text_IO.Put_Line ("architecture:crypto-import:" & Path);
         end if;
      end if;

      if Has_Boundary_Term (Line) then
         Report.Boundary_Term_Hits := Report.Boundary_Term_Hits + 1;
         Ada.Text_IO.Put_Line ("architecture:boundary-term:" & Path);
      end if;
   end Check_Line;

   procedure Check_File (Path : String; Report : in out Validation_Report) is
      File : Ada.Text_IO.File_Type;
   begin
      if not Is_Ada_Source (Path) then
         return;
      end if;

      Report.Files_Checked := Report.Files_Checked + 1;
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Check_Line (Path, Ada.Text_IO.Get_Line (File), Report);
      end loop;
      Ada.Text_IO.Close (File);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Check_File;

   procedure Check_Tree (Root : String; Report : in out Validation_Report);

   procedure Visit
     (Directory_Entry : Ada.Directories.Directory_Entry_Type;
      Report          : in out Validation_Report)
   is
      Path : constant String := Ada.Directories.Full_Name (Directory_Entry);
      Kind : constant Ada.Directories.File_Kind := Ada.Directories.Kind (Directory_Entry);
   begin
      if Kind = Ada.Directories.Directory then
         Check_Tree (Path, Report);
      elsif Kind = Ada.Directories.Ordinary_File then
         Check_File (Path, Report);
      end if;
   end Visit;

   procedure Check_Tree (Root : String; Report : in out Validation_Report) is
      Search : Ada.Directories.Search_Type;
   begin
      if not Ada.Directories.Exists (Root) then
         return;
      end if;

      Ada.Directories.Start_Search
        (Search    => Search,
         Directory => Root,
         Pattern   => "",
         Filter    => [Ada.Directories.Ordinary_File => True,
                       Ada.Directories.Directory     => True,
                       Ada.Directories.Special_File  => False]);

      while Ada.Directories.More_Entries (Search) loop
         declare
            Item : Ada.Directories.Directory_Entry_Type;
         begin
            Ada.Directories.Get_Next_Entry (Search, Item);
            declare
               Name : constant String := Ada.Directories.Simple_Name (Item);
            begin
               if Name /= "." and then Name /= ".."
                 and then Name /= "alire"
                 and then Name /= "config"
                 and then Name /= "obj"
                 and then Name /= "bin"
               then
                  Visit (Item, Report);
               end if;
            end;
         end;
      end loop;

      Ada.Directories.End_Search (Search);
   exception
      when others =>
         if Ada.Directories.More_Entries (Search) then
            Ada.Directories.End_Search (Search);
         end if;
         raise;
   end Check_Tree;

   procedure Validate (Report : out Validation_Report) is
      Prefix : constant String :=
        (if Ada.Directories.Exists ("src/public") then ""
         elsif Ada.Directories.Exists ("../../src/public") then "../../"
         else "");
   begin
      Report := (others => 0);
      Check_Tree (Prefix & "src/public", Report);
      Check_Tree (Prefix & "src/adapters", Report);
      Check_Tree (Prefix & "crates/identity_examples", Report);
      Check_Tree (Prefix & "crates/identity_conformance", Report);
      Check_Tree (Prefix & "crates/identity_tools", Report);
   end Validate;

   function Passed (Report : Validation_Report) return Boolean is
     (Report.Internal_Dependency_Hits = 0
      and then Report.Crypto_Import_Violations = 0
      and then Report.Boundary_Term_Hits = 0);

end Identity_Tools_Architecture;
