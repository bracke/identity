with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Text_IO;

package body Identity_Tools_Secret_Leaks is
   use type Ada.Directories.File_Kind;

   function Contains (Line : String; Pattern : String) return Boolean is
     (Ada.Strings.Fixed.Index (Line, Pattern) /= 0);

   function Is_Scannable_Text (Path : String) return Boolean is
     (Path'Length >= 3
      and then (Contains (Path, ".md")
                or else Contains (Path, ".txt")
                or else Contains (Path, ".json")
                or else Contains (Path, ".toml")
                or else Contains (Path, ".gpr")
                or else Contains (Path, ".ads")
                or else Contains (Path, ".adb")));

   function Has_Canary_Secret (Line : String) return Boolean is
     (Contains (Line, "CAN" & "ARY-password-123")
      or else Contains (Line, "correct horse battery " & "staple")
      or else Contains (Line, "session bearer " & "secret")
      or else Contains (Line, "reset correct horse battery " & "staple"));

   procedure Check_File (Path : String; Report : in out Scan_Report) is
      File : Ada.Text_IO.File_Type;
   begin
      if not Is_Scannable_Text (Path) then
         return;
      end if;

      Report.Files_Checked := Report.Files_Checked + 1;
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         if Has_Canary_Secret (Ada.Text_IO.Get_Line (File)) then
            Report.Canary_Hits := Report.Canary_Hits + 1;
            Ada.Text_IO.Put_Line ("secret-leak:canary:" & Path);
         end if;
      end loop;
      Ada.Text_IO.Close (File);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Check_File;

   procedure Check_Tree (Root : String; Report : in out Scan_Report);

   procedure Visit
     (Directory_Entry : Ada.Directories.Directory_Entry_Type;
      Report          : in out Scan_Report)
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

   procedure Check_Tree (Root : String; Report : in out Scan_Report) is
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

   procedure Check_Path (Path : String; Report : in out Scan_Report) is
   begin
      if not Ada.Directories.Exists (Path) then
         return;
      end if;

      if Ada.Directories.Kind (Path) = Ada.Directories.Directory then
         Check_Tree (Path, Report);
      elsif Ada.Directories.Kind (Path) = Ada.Directories.Ordinary_File then
         Check_File (Path, Report);
      end if;
   end Check_Path;

   procedure Scan (Report : out Scan_Report) is
      Prefix : constant String :=
        (if Ada.Directories.Exists ("src/public") then ""
         elsif Ada.Directories.Exists ("../../src/public") then "../../"
         else "");
   begin
      Report := (others => 0);
      Check_Path (Prefix & "README.md", Report);
      Check_Path (Prefix & "SECURITY.md", Report);
      Check_Path (Prefix & "CHANGELOG.md", Report);
      Check_Path (Prefix & "CONTRIBUTING.md", Report);
      Check_Path (Prefix & "docs", Report);
      Check_Path (Prefix & "registries", Report);
      Check_Path (Prefix & "fixtures", Report);
      Check_Path (Prefix & "tools", Report);
      Check_Path (Prefix & "crates/identity_examples", Report);
      Check_Path (Prefix & "crates/identity_conformance", Report);
      Check_Path (Prefix & "crates/identity_tools", Report);
   end Scan;

   function Passed (Report : Scan_Report) return Boolean is
     (Report.Canary_Hits = 0);

end Identity_Tools_Secret_Leaks;
