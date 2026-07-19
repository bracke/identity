with Ada.Characters.Handling;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

package body Identity_Tools_Documentation is

   use Ada.Strings.Unbounded;
   use type Ada.Directories.File_Kind;
   use type Ada.Directories.File_Size;

   Max_Paths : constant := 1024;

   type Path_Vector is array (1 .. Max_Paths) of Unbounded_String;

   type Path_List is record
      Count : Natural := 0;
      Item  : Path_Vector;
   end record;

   type Flag_Vector is array (1 .. Max_Paths) of Boolean;

   ---------------------------------------------------------------------------
   --  Small text helpers
   ---------------------------------------------------------------------------

   function Contains (Line : String; Pattern : String) return Boolean is
     (Ada.Strings.Fixed.Index (Line, Pattern) /= 0);

   function Has_Suffix (Value : String; Suffix : String) return Boolean is
     (Value'Length >= Suffix'Length
      and then Value (Value'Last - Suffix'Length + 1 .. Value'Last) = Suffix);

   function Lower (Value : String) return String is
     (Ada.Characters.Handling.To_Lower (Value));

   procedure Append_Unique (List : in out Path_List; Value : String) is
   begin
      for Index in 1 .. List.Count loop
         if To_String (List.Item (Index)) = Value then
            return;
         end if;
      end loop;

      if List.Count < Max_Paths then
         List.Count := List.Count + 1;
         List.Item (List.Count) := To_Unbounded_String (Value);
      end if;
   end Append_Unique;

   ---------------------------------------------------------------------------
   --  Unresolved-placeholder markers.
   --
   --  The markers are assembled from fragments so that this gate does not flag
   --  its own source text, exactly as the secret-leak and architecture gates do
   --  for the patterns they hunt for.
   ---------------------------------------------------------------------------

   Marker_Count : constant := 5;

   function Marker (Index : Positive) return String is
     (case Index is
        when 1      => "TO" & "DO",
        when 2      => "T" & "BD",
        when 3      => "FIX" & "ME",
        when 4      => "X" & "X" & "X",
        when others => "<place" & "holder");

   ---------------------------------------------------------------------------
   --  Required documentation set
   ---------------------------------------------------------------------------

   type Required_Document is
     (Readme,
      Changelog,
      Security_Notes,
      Contributing,
      Conduct,
      License_Text,
      Architecture,
      Threat_Model);

   function Image (Document : Required_Document) return String is
     (case Document is
        when Readme         => "README.md",
        when Changelog      => "CHANGELOG.md",
        when Security_Notes => "SECURITY.md",
        when Contributing   => "CONTRIBUTING.md",
        when Conduct        => "CODE_OF_CONDUCT.md",
        when License_Text   => "LICENSE",
        when Architecture   => "docs/architecture.md",
        when Threat_Model   => "docs/threat-model.md");

   ---------------------------------------------------------------------------
   --  Path resolution: work from the repository root and from crates/<crate>/
   ---------------------------------------------------------------------------

   function Prefix return String is
     (if Ada.Directories.Exists ("src/public") then ""
      elsif Ada.Directories.Exists ("../../src/public") then "../../"
      else "");

   ---------------------------------------------------------------------------
   --  File presence
   ---------------------------------------------------------------------------

   function Present_And_Filled (Path : String) return Boolean is
   begin
      return Ada.Directories.Exists (Path)
        and then Ada.Directories.Kind (Path) = Ada.Directories.Ordinary_File
        and then Ada.Directories.Size (Path) > 0;
   exception
      when others =>
         return False;
   end Present_And_Filled;

   ---------------------------------------------------------------------------
   --  Documentation file collection
   ---------------------------------------------------------------------------

   procedure Collect_Markdown (Root : String; List : in out Path_List) is
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
               Path : constant String := Root & "/" & Name;
            begin
               if Name /= "." and then Name /= ".." then
                  if Ada.Directories.Kind (Item) = Ada.Directories.Directory then
                     Collect_Markdown (Path, List);
                  elsif Has_Suffix (Name, ".md") then
                     Append_Unique (List, Path);
                  end if;
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
   end Collect_Markdown;

   ---------------------------------------------------------------------------
   --  Check 2: required documents exist and are non-empty
   ---------------------------------------------------------------------------

   procedure Check_Required
     (Root   : String;
      List   : in out Path_List;
      Report : in out Validation_Report)
   is
   begin
      for Document in Required_Document loop
         declare
            Relative : constant String := Image (Document);
            Path     : constant String := Root & Relative;
         begin
            Report.Required_Documents := Report.Required_Documents + 1;

            if not Ada.Directories.Exists (Path) then
               Report.Missing_Required := Report.Missing_Required + 1;
               Ada.Text_IO.Put_Line ("documentation:missing-required:" & Relative);
            elsif not Present_And_Filled (Path) then
               Report.Empty_Required := Report.Empty_Required + 1;
               Ada.Text_IO.Put_Line ("documentation:empty-required:" & Relative);
            else
               Append_Unique (List, Path);
            end if;
         end;
      end loop;
   end Check_Required;

   ---------------------------------------------------------------------------
   --  Check 2b: every docs/ai/<name>.md referenced from another document exists
   ---------------------------------------------------------------------------

   procedure Check_References
     (Root   : String;
      List   : Path_List;
      Report : in out Validation_Report)
   is
      Reference_Prefix : constant String := "docs/ai/";
      Seen             : Path_List;
      File             : Ada.Text_IO.File_Type;

      procedure Check_One (Reference : String) is
         Path : constant String := Root & Reference;
      begin
         for Index in 1 .. Seen.Count loop
            if To_String (Seen.Item (Index)) = Reference then
               return;
            end if;
         end loop;

         Append_Unique (Seen, Reference);
         Report.Referenced_Documents := Report.Referenced_Documents + 1;

         if not Present_And_Filled (Path) then
            Report.Missing_Referenced := Report.Missing_Referenced + 1;
            Ada.Text_IO.Put_Line ("documentation:missing-referenced:" & Reference);
         end if;
      end Check_One;

      procedure Scan_Line (Line : String) is
         Start : Natural := Line'First;
      begin
         loop
            declare
               Hit : constant Natural :=
                 Ada.Strings.Fixed.Index (Line (Start .. Line'Last), Reference_Prefix);
            begin
               exit when Hit = 0;

               declare
                  Last : Natural := Hit + Reference_Prefix'Length - 1;
               begin
                  while Last < Line'Last
                    and then (Ada.Characters.Handling.Is_Alphanumeric (Line (Last + 1))
                              or else Line (Last + 1) = '-'
                              or else Line (Last + 1) = '_'
                              or else Line (Last + 1) = '.')
                  loop
                     Last := Last + 1;
                  end loop;

                  declare
                     Reference : constant String := Line (Hit .. Last);
                  begin
                     if Has_Suffix (Reference, ".md") then
                        Check_One (Reference);
                     end if;
                  end;

                  exit when Last >= Line'Last;
                  Start := Last + 1;
               end;
            end;
         end loop;
      end Scan_Line;
   begin
      for Index in 1 .. List.Count loop
         declare
            Path : constant String := To_String (List.Item (Index));
         begin
            Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
            while not Ada.Text_IO.End_Of_File (File) loop
               Scan_Line (Ada.Text_IO.Get_Line (File));
            end loop;
            Ada.Text_IO.Close (File);
         end;
      end loop;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Check_References;

   ---------------------------------------------------------------------------
   --  Check 1: documentation artifacts named in the release-artifact registry
   ---------------------------------------------------------------------------

   procedure Check_Artifact_Documents
     (Root   : String;
      Report : in out Validation_Report)
   is
      Registry : constant String := Root & "registries/release-artifacts.json";
      File     : Ada.Text_IO.File_Type;

      procedure Check_Token (Token : String) is
         Path : constant String := Root & Token;
      begin
         if not Has_Suffix (Token, ".md") then
            return;
         end if;

         Report.Artifact_Documents := Report.Artifact_Documents + 1;

         if not Present_And_Filled (Path) then
            Report.Missing_Artifact_Docs := Report.Missing_Artifact_Docs + 1;
            Ada.Text_IO.Put_Line ("documentation:missing-artifact-document:" & Token);
         end if;
      end Check_Token;

      procedure Scan_Line (Line : String) is
         Open_Quote : Natural := 0;
      begin
         for Index in Line'Range loop
            if Line (Index) = '"' then
               if Open_Quote = 0 then
                  Open_Quote := Index;
               else
                  Check_Token (Line (Open_Quote + 1 .. Index - 1));
                  Open_Quote := 0;
               end if;
            end if;
         end loop;
      end Scan_Line;
   begin
      if not Ada.Directories.Exists (Registry) then
         Report.Missing_Artifact_Docs := Report.Missing_Artifact_Docs + 1;
         Ada.Text_IO.Put_Line
           ("documentation:missing-artifact-registry:registries/release-artifacts.json");
         return;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Registry);
      while not Ada.Text_IO.End_Of_File (File) loop
         Scan_Line (Ada.Text_IO.Get_Line (File));
      end loop;
      Ada.Text_IO.Close (File);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Check_Artifact_Documents;

   ---------------------------------------------------------------------------
   --  Check 3: no unresolved placeholder markers in documentation
   ---------------------------------------------------------------------------

   procedure Check_Placeholders
     (List   : Path_List;
      Report : in out Validation_Report)
   is
      File : Ada.Text_IO.File_Type;
   begin
      for Index in 1 .. List.Count loop
         declare
            Path : constant String := To_String (List.Item (Index));
         begin
            Report.Documents_Checked := Report.Documents_Checked + 1;
            Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
            while not Ada.Text_IO.End_Of_File (File) loop
               declare
                  Line : constant String := Ada.Text_IO.Get_Line (File);
               begin
                  for Which in 1 .. Marker_Count loop
                     if Contains (Line, Marker (Which)) then
                        Report.Placeholder_Hits := Report.Placeholder_Hits + 1;
                        Ada.Text_IO.Put_Line
                          ("documentation:placeholder:" & Path & ":" & Marker (Which));
                     end if;
                  end loop;
               end;
            end loop;
            Ada.Text_IO.Close (File);
         end;
      end loop;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Check_Placeholders;

   ---------------------------------------------------------------------------
   --  Check 4: every public package family is named in the package map
   ---------------------------------------------------------------------------

   procedure Collect_Areas (Root : String; Areas : in out Path_List) is
      Search : Ada.Directories.Search_Type;
      Public : constant String := Root & "src/public";
   begin
      if not Ada.Directories.Exists (Public) then
         return;
      end if;

      Ada.Directories.Start_Search
        (Search    => Search,
         Directory => Public,
         Pattern   => "",
         Filter    => [Ada.Directories.Ordinary_File => True,
                       Ada.Directories.Directory     => False,
                       Ada.Directories.Special_File  => False]);

      while Ada.Directories.More_Entries (Search) loop
         declare
            Item : Ada.Directories.Directory_Entry_Type;
         begin
            Ada.Directories.Get_Next_Entry (Search, Item);
            declare
               Name   : constant String := Ada.Directories.Simple_Name (Item);
               Head   : constant String := "identity-";
               Cursor : Natural;
            begin
               if Has_Suffix (Name, ".ads")
                 and then Name'Length > Head'Length
                 and then Name (Name'First .. Name'First + Head'Length - 1) = Head
               then
                  Cursor := Name'First + Head'Length;
                  while Cursor <= Name'Last
                    and then Name (Cursor) /= '-'
                    and then Name (Cursor) /= '.'
                  loop
                     Cursor := Cursor + 1;
                  end loop;

                  Append_Unique
                    (Areas, Lower (Name (Name'First + Head'Length .. Cursor - 1)));
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
   end Collect_Areas;

   procedure Check_Package_Map
     (Root   : String;
      Report : in out Validation_Report)
   is
      Map_Path : constant String := Root & "docs/ai/package-map.md";
      Areas    : Path_List;
      Found    : Flag_Vector := [others => False];
      File     : Ada.Text_IO.File_Type;
   begin
      Collect_Areas (Root, Areas);
      Report.Public_Areas := Areas.Count;

      if not Present_And_Filled (Map_Path) then
         Report.Unmapped_Areas := Report.Unmapped_Areas + Areas.Count;
         Ada.Text_IO.Put_Line
           ("documentation:missing-package-map:docs/ai/package-map.md");
         return;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Map_Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : constant String := Lower (Ada.Text_IO.Get_Line (File));
         begin
            for Index in 1 .. Areas.Count loop
               if not Found (Index)
                 and then Contains (Line, "identity." & To_String (Areas.Item (Index)))
               then
                  Found (Index) := True;
               end if;
            end loop;
         end;
      end loop;
      Ada.Text_IO.Close (File);

      for Index in 1 .. Areas.Count loop
         if not Found (Index) then
            Report.Unmapped_Areas := Report.Unmapped_Areas + 1;
            Ada.Text_IO.Put_Line
              ("documentation:unmapped-area:" & To_String (Areas.Item (Index)));
         end if;
      end loop;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Check_Package_Map;

   ---------------------------------------------------------------------------
   --  Check 5: CHANGELOG.md carries a section for the declared crate version
   ---------------------------------------------------------------------------

   function Crate_Version (Root : String) return String is
      Path   : constant String := Root & "alire.toml";
      File   : Ada.Text_IO.File_Type;
      Result : Unbounded_String;
   begin
      if not Ada.Directories.Exists (Path) then
         return "";
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line  : constant String := Ada.Text_IO.Get_Line (File);
            Head  : constant Natural := Ada.Strings.Fixed.Index (Line, "version");
            First : Natural;
            Last  : Natural;
         begin
            if Head = Line'First and then Length (Result) = 0 then
               First := Ada.Strings.Fixed.Index (Line, """");
               if First /= 0 then
                  Last := Ada.Strings.Fixed.Index (Line (First + 1 .. Line'Last), """");
                  if Last /= 0 then
                     Result := To_Unbounded_String (Line (First + 1 .. Last - 1));
                  end if;
               end if;
            end if;
         end;
      end loop;
      Ada.Text_IO.Close (File);
      return To_String (Result);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Crate_Version;

   procedure Check_Changelog_Section
     (Root   : String;
      Report : in out Validation_Report)
   is
      Version : constant String := Crate_Version (Root);
      Path    : constant String := Root & "CHANGELOG.md";
      File    : Ada.Text_IO.File_Type;
      Found   : Boolean := False;
   begin
      if Version = "" then
         Report.Missing_Changelog_Section := Report.Missing_Changelog_Section + 1;
         Ada.Text_IO.Put_Line ("documentation:missing-crate-version:alire.toml");
         return;
      end if;

      if not Present_And_Filled (Path) then
         Report.Missing_Changelog_Section := Report.Missing_Changelog_Section + 1;
         Ada.Text_IO.Put_Line ("documentation:missing-changelog:CHANGELOG.md");
         return;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (File);
         begin
            if Line'Length > 0
              and then Line (Line'First) = '#'
              and then Contains (Line, Version)
            then
               Found := True;
            end if;
         end;
      end loop;
      Ada.Text_IO.Close (File);

      if not Found then
         Report.Missing_Changelog_Section := Report.Missing_Changelog_Section + 1;
         Ada.Text_IO.Put_Line ("documentation:missing-changelog-section:" & Version);
      end if;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Check_Changelog_Section;

   ---------------------------------------------------------------------------
   --  Entry points
   ---------------------------------------------------------------------------

   procedure Validate (Report : out Validation_Report) is
      Root      : constant String := Prefix;
      Documents : Path_List;
   begin
      Report := (others => 0);

      Check_Required (Root, Documents, Report);
      Collect_Markdown (Root & "docs", Documents);
      Check_References (Root, Documents, Report);
      Check_Artifact_Documents (Root, Report);
      Check_Placeholders (Documents, Report);
      Check_Package_Map (Root, Report);
      Check_Changelog_Section (Root, Report);
   end Validate;

   function Passed (Report : Validation_Report) return Boolean is
     (Report.Documents_Checked > 0
      and then Report.Public_Areas > 0
      and then Report.Missing_Required = 0
      and then Report.Empty_Required = 0
      and then Report.Missing_Referenced = 0
      and then Report.Missing_Artifact_Docs = 0
      and then Report.Placeholder_Hits = 0
      and then Report.Unmapped_Areas = 0
      and then Report.Missing_Changelog_Section = 0);

end Identity_Tools_Documentation;
