--  release_check -- release-gate orchestration for identity.
--
--  Runs every mandatory V1 gate IN ORDER, records each run's real outcome
--  under generated/evidence/<name>.txt, prints a per-gate marker
--  (release-check:<gate>:passed|failed|warning:<detail>), and fails overall if
--  any gate failed. Everything the gate decides on is computed in Ada -- git
--  status filtering, the alire.toml version parse, gnatprove output parsing,
--  the proof-scope.json parse, SHA-256 digests, the api-surface walk. Builds,
--  suite binaries, gnatprove and tar are spawned as external programs through
--  project_tools.Processes, the same way gprbuild and gcov are invoked.
--
--  Usage: release_check [repo-root]  (defaults to the current directory).

with Ada.Characters.Handling;
with Ada.Command_Line;
with Ada.Directories;
with Ada.Streams;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with GNAT.OS_Lib;

with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Text;

with Representation;
with Representation.Documents;
with Representation.Inputs;
with Representation.JSON.Documents;

with CryptoLib.Hashes;

procedure Release_Check is

   package Files renames Project_Tools.Files;
   package Processes renames Project_Tools.Processes;
   package DM renames Representation.Documents;
   package JD renames Representation.JSON.Documents;

   use Ada.Strings.Unbounded;
   use type DM.Node_Ref;
   use type DM.Node_Kind;

   subtype Byte is Representation.Byte;
   subtype Byte_Array is Representation.Byte_Array;

   type Str_Array is array (Positive range <>) of Unbounded_String;

   LF : constant Character := Character'Val (16#0A#);

   Halt : exception;
   --  Raised to stop the run early (the shell's mid-stream "exit 1"): the exit
   --  status is already set to Failure when it is raised.

   Failed : Boolean := False;
   --  Set by any gate that fails but does not stop the run (the shell FAILED=1).

   Last_Output : Unbounded_String;
   --  Captured stdout+stderr of the most recent spawned command.

   function U (Item : String) return Unbounded_String
     renames To_Unbounded_String;

   function Img (Value : Integer) return String is
     (Ada.Strings.Fixed.Trim (Value'Image, Ada.Strings.Both));

   function Contains (Text : String; Pattern : String) return Boolean is
     (Project_Tools.Text.Contains (Text, Pattern));

   function Read_File (Path : String) return String is
     (if Files.File_Exists (Path) then Files.Read_Raw_File (Path) else "");

   ---------------------------------------------------------------------------
   --  Repository root and the paths the gates read.
   ---------------------------------------------------------------------------

   Root : constant String :=
     (if Ada.Command_Line.Argument_Count >= 1
      then Ada.Directories.Full_Name (Ada.Command_Line.Argument (1))
      else Ada.Directories.Current_Directory);

   Evidence_Dir : constant String := Root & "/generated/evidence";
   Release_Dir  : constant String := Root & "/generated/release";
   Scratch_Dir  : constant String := Files.Temp_Dir & "/identity-release-check";
   Cap_File     : constant String := Scratch_Dir & "/capture.txt";

   Archive : constant String := Release_Dir & "/identity-source.tar.gz";

   ---------------------------------------------------------------------------
   --  Output + evidence
   ---------------------------------------------------------------------------

   procedure Put_Line (Item : String) renames Ada.Text_IO.Put_Line;

   procedure Section (Title : String) is
   begin
      Put_Line ("== " & Title & " ==");
   end Section;

   procedure Fatal (Marker : String) is
   begin
      Put_Line (Marker);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      raise Halt;
   end Fatal;

   --  record <name> <status> <detail>: write the evidence file, print the
   --  marker, and fail the run unless the status is "passed".
   procedure Record_Evidence (Name : String; Status : String; Detail : String)
   is
   begin
      Files.Write_Raw_File
        (Evidence_Dir & "/" & Name & ".txt",
         "status:" & Status & LF & "detail:" & Detail & LF);
      Put_Line ("release-check:" & Name & ":" & Status & ":" & Detail);
      if Status /= "passed" then
         Failed := True;
      end if;
   end Record_Evidence;

   --  Print the last Count lines of Text (the shell's "tail -N" diagnostics).
   procedure Print_Tail (Text : String; Count : Positive) is
      Seen  : Natural := 0;
      First : Positive := Text'First;
   begin
      if Text'Length = 0 then
         return;
      end if;
      for I in reverse Text'First .. Text'Last - 1 loop
         if Text (I) = LF then
            Seen := Seen + 1;
            if Seen = Count then
               First := I + 1;
               exit;
            end if;
         end if;
      end loop;
      Ada.Text_IO.Put (Text (First .. Text'Last));
      if Text (Text'Last) /= LF then
         Ada.Text_IO.New_Line;
      end if;
   end Print_Tail;

   ---------------------------------------------------------------------------
   --  Command execution
   ---------------------------------------------------------------------------

   --  Run Command in Dir through /bin/sh, capturing stdout+stderr (2>&1) into
   --  Last_Output, and return the exit status -- the exact semantics of the
   --  shell's  out=$(cd dir && cmd 2>&1); rc=$?.
   function Run_Cap (Dir : String; Command : String) return Integer is
      RC : constant Integer :=
        Processes.Run_Shell_In_Directory
          (Directory   => Dir,
           Command     => Command,
           Quiet       => True,
           Output_File => Cap_File);
   begin
      Last_Output := U (Read_File (Cap_File));
      return RC;
   end Run_Cap;

   --  run_crate <evidence-name> <crate-dir> <executable>: build the crate, then
   --  run its binary and record the outcome.
   procedure Run_Crate (Name : String; Dir : String; Exe : String) is
   begin
      if Run_Cap (Dir, "alr build") /= 0 then
         Record_Evidence (Name, "failed", "build failed");
         Print_Tail (To_String (Last_Output), 20);
         return;
      end if;
      declare
         RC : constant Integer := Run_Cap (Dir, "./bin/" & Exe);
      begin
         if RC = 0 then
            Record_Evidence (Name, "passed", "exit 0");
         else
            Record_Evidence (Name, "failed", "exit " & Img (RC));
            Print_Tail (To_String (Last_Output), 20);
         end if;
      end;
   end Run_Crate;

   ---------------------------------------------------------------------------
   --  String / line utilities
   ---------------------------------------------------------------------------

   --  For the matching line of Text, return the substring from Marker to the
   --  end of that line (Strip => from just after Marker). Last selects the last
   --  matching line rather than the first. Mirrors grep -o '<marker>.*'.
   function Extract_Marker
     (Text   : String;
      Marker : String;
      Last   : Boolean;
      Strip  : Boolean) return String
   is
      Result : Unbounded_String;
      Found  : Boolean := False;
      Start  : Positive := (if Text'Length = 0 then 1 else Text'First);

      procedure Consider (Line : String) is
         P : constant Natural := Project_Tools.Text.Index (Line, Marker);
      begin
         if P /= 0 and then (not Found or else Last) then
            Found := True;
            if Strip then
               Result := U (Line (P + Marker'Length .. Line'Last));
            else
               Result := U (Line (P .. Line'Last));
            end if;
         end if;
      end Consider;
   begin
      if Text'Length = 0 then
         return "";
      end if;
      for I in Text'Range loop
         if Text (I) = LF then
            Consider (Text (Start .. I - 1));
            Start := I + 1;
         end if;
      end loop;
      if Start <= Text'Last then
         Consider (Text (Start .. Text'Last));
      end if;
      return To_String (Result);
   end Extract_Marker;

   --  The last line of Text, ignoring trailing newlines (tail -1 of a value
   --  that command substitution has already stripped of trailing newlines).
   function Last_Line (Text : String) return String is
      Last : Integer := Text'Last;
   begin
      if Text'Length = 0 then
         return "";
      end if;
      while Last >= Text'First and then Text (Last) = LF loop
         Last := Last - 1;
      end loop;
      if Last < Text'First then
         return "";
      end if;
      declare
         First : Integer := Last;
      begin
         while First >= Text'First and then Text (First) /= LF loop
            First := First - 1;
         end loop;
         return Text (First + 1 .. Last);
      end;
   end Last_Line;

   --  Count the newline-terminated lines in Text (wc -l semantics).
   function Line_Count (Text : String) return Natural is
      Count : Natural := 0;
   begin
      for C of Text loop
         if C = LF then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Line_Count;

   ---------------------------------------------------------------------------
   --  Version metadata
   ---------------------------------------------------------------------------

   --  Extract the value of the first  version = "..."  line of an alire.toml
   --  (the shell's sed 's/^version *= *"\([^"]*\)".*/\1/p' | head -1).
   function Parse_Version (Path : String) return String is
      Content : constant String := Read_File (Path);
      Start   : Positive := (if Content'Length = 0 then 1 else Content'First);

      function From_Line (Line : String) return String is
         P : Positive := Line'First;
      begin
         if not Project_Tools.Text.Starts_With (Line, "version") then
            return "";
         end if;
         P := Line'First + 7;
         while P <= Line'Last and then Line (P) = ' ' loop
            P := P + 1;
         end loop;
         if P > Line'Last or else Line (P) /= '=' then
            return "";
         end if;
         P := P + 1;
         while P <= Line'Last and then Line (P) = ' ' loop
            P := P + 1;
         end loop;
         if P > Line'Last or else Line (P) /= '"' then
            return "";
         end if;
         P := P + 1;
         declare
            First : constant Positive := P;
         begin
            while P <= Line'Last and then Line (P) /= '"' loop
               P := P + 1;
            end loop;
            if P > Line'Last then
               return "";
            end if;
            return Line (First .. P - 1);
         end;
      end From_Line;
   begin
      if Content'Length = 0 then
         return "";
      end if;
      for I in Content'Range loop
         if Content (I) = LF then
            declare
               V : constant String := From_Line (Content (Start .. I - 1));
            begin
               if V'Length > 0 then
                  return V;
               end if;
            end;
            Start := I + 1;
         end if;
      end loop;
      if Start <= Content'Last then
         return From_Line (Content (Start .. Content'Last));
      end if;
      return "";
   end Parse_Version;

   --  ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$
   function Is_Semver (V : String) return Boolean is
      Pos : Integer := V'First;

      function Digit_Run return Boolean is
         Seen : Natural := 0;
      begin
         while Pos <= V'Last and then V (Pos) in '0' .. '9' loop
            Pos := Pos + 1;
            Seen := Seen + 1;
         end loop;
         return Seen > 0;
      end Digit_Run;
   begin
      if V'Length = 0 then
         return False;
      end if;
      if not Digit_Run then
         return False;
      end if;
      if Pos > V'Last or else V (Pos) /= '.' then
         return False;
      end if;
      Pos := Pos + 1;
      if not Digit_Run then
         return False;
      end if;
      if Pos > V'Last or else V (Pos) /= '.' then
         return False;
      end if;
      Pos := Pos + 1;
      if not Digit_Run then
         return False;
      end if;
      if Pos > V'Last then
         return True;
      end if;
      if V (Pos) /= '-' then
         return False;
      end if;
      Pos := Pos + 1;
      if Pos > V'Last then
         return False;
      end if;
      while Pos <= V'Last loop
         if V (Pos) in '0' .. '9' | 'A' .. 'Z' | 'a' .. 'z' | '.' then
            Pos := Pos + 1;
         else
            return False;
         end if;
      end loop;
      return True;
   end Is_Semver;

   ---------------------------------------------------------------------------
   --  SHA-256
   ---------------------------------------------------------------------------

   function SHA256_Hex (Path : String) return String is
      Content : constant String := Read_File (Path);
      Data    : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Content'Length));
      Digest  : CryptoLib.Hashes.SHA256_Digest;
      Chars   : constant String := "0123456789abcdef";
      Hex     : String (1 .. 64);
   begin
      for I in Content'Range loop
         Data (Ada.Streams.Stream_Element_Offset (I - Content'First + 1)) :=
           Ada.Streams.Stream_Element (Character'Pos (Content (I)));
      end loop;
      Digest := CryptoLib.Hashes.SHA256 (Data);
      for I in Digest'Range loop
         declare
            Value : constant Natural := Natural (Digest (I));
         begin
            Hex (2 * I - 1) := Chars (Value / 16 + 1);
            Hex (2 * I)     := Chars (Value mod 16 + 1);
         end;
      end loop;
      return Hex;
   end SHA256_Hex;

   ---------------------------------------------------------------------------
   --  proof-scope.json (Representation JSON)
   ---------------------------------------------------------------------------

   function To_Bytes (Value : String) return Byte_Array is
      Result : Byte_Array (1 .. Value'Length);
   begin
      for I in Result'Range loop
         Result (I) := Byte (Character'Pos (Value (Value'First + I - 1)));
      end loop;
      return Result;
   end To_Bytes;

   function To_Str (Value : Byte_Array) return String is
      Result : String (1 .. Value'Length);
   begin
      for I in Result'Range loop
         Result (I) := Character'Val (Natural (Value (Value'First + I - 1)));
      end loop;
      return Result;
   end To_Str;

   --  The non-excluded package names listed by registries/proof-scope.json.
   function Proof_Packages (Path : String) return Str_Array is
      Content : constant String := Read_File (Path);
      Buffer  : array (1 .. 256) of Unbounded_String;
      Count   : Natural := 0;
   begin
      if Content'Length = 0 then
         return [1 .. 0 => <>];
      end if;
      declare
         Data    : aliased constant Byte_Array := To_Bytes (Content);
         Src     : aliased Representation.Inputs.Array_Source (Data'Access);
         Doc     : DM.Document
           (Node_Capacity => 8192, Text_Capacity => 131_072);
         Outcome : JD.Decode_Result;
         Root_N  : DM.Node_Ref;
         Pkgs    : DM.Node_Ref;
      begin
         JD.Decode (Doc, Src'Access, Outcome);
         if not Outcome.Ok then
            return [1 .. 0 => <>];
         end if;
         Root_N := DM.Root (Doc);
         Pkgs := DM.Find (Doc, Root_N, To_Bytes ("packages"));
         if Pkgs = DM.No_Node then
            return [1 .. 0 => <>];
         end if;
         for I in 1 .. DM.Length (Doc, Pkgs) loop
            declare
               Ent      : constant DM.Node_Ref := DM.Element (Doc, Pkgs, I);
               Name_N   : constant DM.Node_Ref :=
                 DM.Find (Doc, Ent, To_Bytes ("name"));
               Excl_N   : constant DM.Node_Ref :=
                 DM.Find (Doc, Ent, To_Bytes ("excluded"));
               Excluded : constant Boolean :=
                 Excl_N /= DM.No_Node
                 and then DM.Kind (Doc, Excl_N) = DM.Bool_Node
                 and then DM.Bool_Value (Doc, Excl_N);
            begin
               if Name_N /= DM.No_Node
                 and then DM.Kind (Doc, Name_N) = DM.String_Node
                 and then not Excluded
                 and then Count < Buffer'Last
               then
                  Count := Count + 1;
                  Buffer (Count) := U (To_Str (DM.Text (Doc, Name_N)));
               end if;
            end;
         end loop;
      end;
      return Result : Str_Array (1 .. Count) do
         for K in 1 .. Count loop
            Result (K) := Buffer (K);
         end loop;
      end return;
   end Proof_Packages;

   ---------------------------------------------------------------------------
   --  gnatprove finding classification
   ---------------------------------------------------------------------------

   function Is_Finding (Line : String) return Boolean is
     (Contains (Line, " medium: ")
      or else Contains (Line, " high: ")
      or else Contains (Line, " low: "));

   --  ^[a-z0-9_.-]+\.ad[bs]:[0-9]+:[0-9]+: error:
   function Is_Legality (Line : String) return Boolean is
      Ext : Natural := 0;
      Pos : Integer;
   begin
      for I in Line'First .. Line'Last - 4 loop
         if Line (I .. I + 4) = ".adb:"
           or else Line (I .. I + 4) = ".ads:"
         then
            Ext := I;
            exit;
         end if;
      end loop;
      if Ext = 0 then
         return False;
      end if;
      for I in Line'First .. Ext - 1 loop
         if Line (I) not in
              'a' .. 'z' | '0' .. '9' | '_' | '.' | '-'
         then
            return False;
         end if;
      end loop;
      Pos := Ext + 5;
      if Pos > Line'Last or else Line (Pos) not in '0' .. '9' then
         return False;
      end if;
      while Pos <= Line'Last and then Line (Pos) in '0' .. '9' loop
         Pos := Pos + 1;
      end loop;
      if Pos > Line'Last or else Line (Pos) /= ':' then
         return False;
      end if;
      Pos := Pos + 1;
      if Pos > Line'Last or else Line (Pos) not in '0' .. '9' then
         return False;
      end if;
      while Pos <= Line'Last and then Line (Pos) in '0' .. '9' loop
         Pos := Pos + 1;
      end loop;
      return Pos + 7 <= Line'Last and then Line (Pos .. Pos + 7) = ": error:";
   end Is_Legality;

   function Starts_With (Value : String; Prefix : String) return Boolean is
     (Project_Tools.Text.Starts_With (Value, Prefix));

   ---------------------------------------------------------------------------
   --  Directory listing helpers
   ---------------------------------------------------------------------------

   --  generated/release/*.txt (excluding artifact-digests.txt), sorted.
   function Release_Txt_Files return Str_Array is
      use Ada.Directories;
      Buffer : array (1 .. 256) of Unbounded_String;
      Count  : Natural := 0;
      Search : Search_Type;
      Ent    : Directory_Entry_Type;
   begin
      if not Exists (Release_Dir) then
         return [1 .. 0 => <>];
      end if;
      Start_Search
        (Search, Release_Dir, "*.txt",
         [Ordinary_File => True, others => False]);
      while More_Entries (Search) loop
         Get_Next_Entry (Search, Ent);
         declare
            Name : constant String := Simple_Name (Ent);
         begin
            if Name /= "artifact-digests.txt" and then Count < Buffer'Last then
               Count := Count + 1;
               Buffer (Count) := U (Name);
            end if;
         end;
      end loop;
      End_Search (Search);
      for I in 1 .. Count - 1 loop
         for J in I + 1 .. Count loop
            if To_String (Buffer (J)) < To_String (Buffer (I)) then
               declare
                  Tmp : constant Unbounded_String := Buffer (I);
               begin
                  Buffer (I) := Buffer (J);
                  Buffer (J) := Tmp;
               end;
            end if;
         end loop;
      end loop;
      return Result : Str_Array (1 .. Count) do
         for K in 1 .. Count loop
            Result (K) := Buffer (K);
         end loop;
      end return;
   end Release_Txt_Files;

   --  src/public/**/*.ads and src/adapters/**/*.ads, repo-relative, sorted.
   function Api_Specs return Str_Array is
      Public   : constant Files.Path_List :=
        Files.List_Tree (Root & "/src/public", "*.ads");
      Adapters : constant Files.Path_List :=
        Files.List_Tree (Root & "/src/adapters", "*.ads");
      Prefix   : constant String := Root & "/";
      Buffer   : array (1 .. Public'Length + Adapters'Length) of
        Unbounded_String;
      Count    : Natural := 0;

      procedure Add (List : Files.Path_List) is
      begin
         for Item of List loop
            declare
               Full : constant String := To_String (Item);
            begin
               Count := Count + 1;
               if Full'Length > Prefix'Length
                 and then Full (Full'First .. Full'First + Prefix'Length - 1)
                          = Prefix
               then
                  Buffer (Count) :=
                    U (Full (Full'First + Prefix'Length .. Full'Last));
               else
                  Buffer (Count) := U (Full);
               end if;
            end;
         end loop;
      end Add;
   begin
      Add (Public);
      Add (Adapters);
      for I in 1 .. Count - 1 loop
         for J in I + 1 .. Count loop
            if To_String (Buffer (J)) < To_String (Buffer (I)) then
               declare
                  Tmp : constant Unbounded_String := Buffer (I);
               begin
                  Buffer (I) := Buffer (J);
                  Buffer (J) := Tmp;
               end;
            end if;
         end loop;
      end loop;
      return Result : Str_Array (1 .. Count) do
         for K in 1 .. Count loop
            Result (K) := Buffer (K);
         end loop;
      end return;
   end Api_Specs;

   --  Lexicographically first obj/*/gnatprove/gnatprove.out, or "".
   function Gnatprove_Summary return String is
      use Ada.Directories;
      Search : Search_Type;
      Ent    : Directory_Entry_Type;
      Best   : Unbounded_String;
   begin
      if not Exists (Root & "/obj") then
         return "";
      end if;
      Start_Search
        (Search, Root & "/obj", "", [Directory => True, others => False]);
      while More_Entries (Search) loop
         Get_Next_Entry (Search, Ent);
         declare
            Name      : constant String := Simple_Name (Ent);
            Candidate : constant String :=
              Root & "/obj/" & Name & "/gnatprove/gnatprove.out";
         begin
            if Name /= "." and then Name /= ".."
              and then Files.File_Exists (Candidate)
              and then
                (Best = Null_Unbounded_String
                 or else Candidate < To_String (Best))
            then
               Best := U (Candidate);
            end if;
         end;
      end loop;
      End_Search (Search);
      return To_String (Best);
   end Gnatprove_Summary;

   --  Case-insensitive whole-file substring search (grep -qi).
   function Contains_CI (Haystack : String; Needle : String) return Boolean is
     (Contains
        (Ada.Characters.Handling.To_Lower (Haystack),
         Ada.Characters.Handling.To_Lower (Needle)));

   --  Prohibited-file scan of a tar listing line: .pem/.key/.env suffix, or an
   --  id_rsa path component. Mirrors grep -iE
   --  '\.pem$|\.key$|(^|/)id_rsa($|\.)|\.env$'.
   function Prohibited_Line (Line : String) return Boolean is
      Low : constant String := Ada.Characters.Handling.To_Lower (Line);
   begin
      if Project_Tools.Text.Ends_With (Low, ".pem")
        or else Project_Tools.Text.Ends_With (Low, ".key")
        or else Project_Tools.Text.Ends_With (Low, ".env")
      then
         return True;
      end if;
      declare
         P : Natural := Project_Tools.Text.Index (Low, "id_rsa");
      begin
         while P /= 0 loop
            declare
               Before_Ok : constant Boolean :=
                 P = Low'First or else Low (P - 1) = '/';
               After      : constant Integer := P + 6;
               After_Ok  : constant Boolean :=
                 After > Low'Last or else Low (After) = '.';
            begin
               if Before_Ok and then After_Ok then
                  return True;
               end if;
            end;
            P := Project_Tools.Text.Index_From (Low, "id_rsa", P + 1);
         end loop;
      end;
      return False;
   end Prohibited_Line;

   --  Second whitespace-delimited field of a git-porcelain line (awk '$2').
   function Porcelain_Path (Line : String) return String is
      P : Integer := Line'First;
   begin
      while P <= Line'Last and then Line (P) = ' ' loop
         P := P + 1;
      end loop;
      while P <= Line'Last and then Line (P) /= ' ' loop
         P := P + 1;
      end loop;
      while P <= Line'Last and then Line (P) = ' ' loop
         P := P + 1;
      end loop;
      declare
         First : constant Integer := P;
      begin
         while P <= Line'Last and then Line (P) /= ' ' loop
            P := P + 1;
         end loop;
         if First > Line'Last then
            return "";
         end if;
         return Line (First .. P - 1);
      end;
   end Porcelain_Path;

   Empty_Args : GNAT.OS_Lib.Argument_List (1 .. 0);

begin
   Ada.Directories.Create_Path (Evidence_Dir);
   Ada.Directories.Create_Path (Release_Dir);
   Ada.Directories.Create_Path (Scratch_Dir);

   ---------------------------------------------------------------------------
   --  version metadata
   ---------------------------------------------------------------------------
   Section ("version metadata");
   declare
      Version : constant String := Parse_Version (Root & "/alire.toml");
   begin
      if Version'Length = 0 then
         Fatal ("release-check:version-metadata:failed:no-version-in-alire.toml");
      elsif not Is_Semver (Version) then
         Fatal ("release-check:version-metadata:failed:malformed:" & Version);
      else
         Put_Line ("release-check:version-metadata:passed:" & Version);
      end if;
   end;

   ---------------------------------------------------------------------------
   --  dependency lockfile
   ---------------------------------------------------------------------------
   Section ("dependency lockfile");
   declare
      Lock : constant String := Root & "/alire/alire.lock";
   begin
      if Files.File_Exists (Lock) and then Read_File (Lock)'Length > 0 then
         Put_Line ("release-check:lockfile:passed:alire/alire.lock");
      else
         Put_Line ("release-check:lockfile:failed:missing-or-empty");
         Failed := True;
      end if;
   end;

   ---------------------------------------------------------------------------
   --  clean repository
   ---------------------------------------------------------------------------
   Section ("clean repository");
   declare
      RC     : constant Integer := Run_Cap (Root, "git status --porcelain");
      Status : constant String := (if RC = 0 then To_String (Last_Output) else "");
      Dirty  : array (1 .. 4096) of Unbounded_String;
      Count  : Natural := 0;
      Start  : Positive := (if Status'Length = 0 then 1 else Status'First);

      procedure Consider (Line : String) is
         Path : constant String := Porcelain_Path (Line);
      begin
         if Path'Length > 0
           and then not Starts_With (Path, "generated/")
           and then not Starts_With (Path, "alire/")
           and then Count < Dirty'Last
         then
            Count := Count + 1;
            Dirty (Count) := U (Path);
         end if;
      end Consider;
   begin
      if Status'Length > 0 then
         for I in Status'Range loop
            if Status (I) = LF then
               Consider (Status (Start .. I - 1));
               Start := I + 1;
            end if;
         end loop;
         if Start <= Status'Last then
            Consider (Status (Start .. Status'Last));
         end if;
      end if;
      if Count = 0 then
         Put_Line ("release-check:clean-repo:passed");
      else
         Put_Line
           ("release-check:clean-repo:warning:uncommitted-source:" & Img (Count));
         for I in 1 .. Natural'Min (Count, 10) loop
            Put_Line ("  " & To_String (Dirty (I)));
         end loop;
      end if;
   end;

   ---------------------------------------------------------------------------
   --  library (development profile)
   ---------------------------------------------------------------------------
   Section ("library");
   if Run_Cap (Root, "alr build") /= 0 then
      Print_Tail (To_String (Last_Output), 20);
      Fatal ("release-check:library:failed");
   end if;

   ---------------------------------------------------------------------------
   --  library (release profile)
   ---------------------------------------------------------------------------
   Section ("library (release profile)");
   if Run_Cap (Root, "alr build --release") /= 0 then
      Print_Tail (To_String (Last_Output), 20);
      Fatal ("release-check:library-release:failed");
   end if;
   Put_Line ("release-check:library-release:passed");

   ---------------------------------------------------------------------------
   --  aunit suite
   ---------------------------------------------------------------------------
   Section ("aunit suite");
   Run_Crate ("aunit", Root & "/crates/identity_tests", "identity_tests");

   ---------------------------------------------------------------------------
   --  code coverage
   ---------------------------------------------------------------------------
   Section ("code coverage");
   declare
      Cov_Bin : constant String :=
        Root & "/crates/identity_tests/bin/identity_coverage";
   begin
      if not Files.File_Exists (Cov_Bin) then
         declare
            Ignored : constant Integer :=
              Run_Cap (Root & "/crates/identity_tests", "alr build");
            pragma Unreferenced (Ignored);
         begin
            null;
         end;
      end if;
      declare
         RC  : constant Integer := Run_Cap (Root, Cov_Bin);
         Captured : constant String := To_String (Last_Output);
      begin
         if RC = 0 then
            Record_Evidence
              ("coverage", "passed",
               Extract_Marker
                 (Captured, "release-check:coverage:passed:",
                  Last => False, Strip => True));
         else
            Record_Evidence
              ("coverage", "failed",
               Extract_Marker
                 (Captured, "release-check:coverage:failed:",
                  Last => True, Strip => True));
            Print_Tail (Captured, 20);
         end if;
      end;
   end;

   ---------------------------------------------------------------------------
   --  repository conformance
   ---------------------------------------------------------------------------
   Section ("repository conformance");
   Run_Crate
     ("conformance", Root & "/crates/identity_conformance",
      "identity_conformance");

   ---------------------------------------------------------------------------
   --  examples
   ---------------------------------------------------------------------------
   Section ("examples");
   Run_Crate
     ("examples", Root & "/crates/identity_examples", "identity_lifecycle");

   ---------------------------------------------------------------------------
   --  concurrency
   ---------------------------------------------------------------------------
   Section ("concurrency");
   declare
      RC  : constant Integer :=
        Run_Cap (Root, Root & "/crates/identity_conformance/bin/identity_concurrency");
      Captured : constant String := To_String (Last_Output);
   begin
      if RC = 0 then
         Record_Evidence
           ("concurrency", "passed",
            Extract_Marker
              (Captured, "identity_concurrency:tasks:", Last => True, Strip => False));
      else
         Record_Evidence
           ("concurrency", "failed", "identity_concurrency reported a failure");
         --  Echo the failing lines (grep ':failed' | head -10).
         declare
            Start : Positive := (if Captured'Length = 0 then 1 else Captured'First);
            Shown : Natural := 0;

            procedure Consider (Line : String) is
            begin
               if Shown < 10 and then Contains (Line, ":failed") then
                  Put_Line (Line);
                  Shown := Shown + 1;
               end if;
            end Consider;
         begin
            if Captured'Length > 0 then
               for I in Captured'Range loop
                  if Captured (I) = LF then
                     Consider (Captured (Start .. I - 1));
                     Start := I + 1;
                  end if;
               end loop;
               if Start <= Captured'Last then
                  Consider (Captured (Start .. Captured'Last));
               end if;
            end if;
         end;
      end if;
   end;

   ---------------------------------------------------------------------------
   --  gnatprove
   ---------------------------------------------------------------------------
   Section ("gnatprove");
   if Processes.Locate_Command ("gnatprove") = "" then
      Record_Evidence ("gnatprove", "failed", "gnatprove not installed");
   else
      declare
         RC : constant Integer :=
           Run_Cap
             (Root,
              "gnatprove -P identity.gpr -aP " & Processes.Shell_Quote (Root & "/../cryptolib")
              & " --mode=all --level=2 -j0 -f");
         Captured       : constant String := To_String (Last_Output);
         Unproved  : Natural := 0;
         Legality  : Natural := 0;
         Missing   : Natural := 0;
         Summary   : constant String := Gnatprove_Summary;
         Summary_C : constant String := Read_File (Summary);
         Start     : Positive := (if Captured'Length = 0 then 1 else Captured'First);

         procedure Classify (Line : String) is
         begin
            if not Starts_With (Line, "cryptolib-") then
               if Is_Finding (Line) then
                  Unproved := Unproved + 1;
               end if;
               if Is_Legality (Line) then
                  Legality := Legality + 1;
               end if;
            end if;
         end Classify;

         pragma Unreferenced (RC);
      begin
         if Captured'Length > 0 then
            for I in Captured'Range loop
               if Captured (I) = LF then
                  Classify (Captured (Start .. I - 1));
                  Start := I + 1;
               end if;
            end loop;
            if Start <= Captured'Last then
               Classify (Captured (Start .. Captured'Last));
            end if;
         end if;

         --  Every non-excluded package must actually be analysed.
         for Name of Proof_Packages (Root & "/registries/proof-scope.json") loop
            if not Contains_CI (Summary_C, To_String (Name)) then
               Missing := Missing + 1;
               Put_Line ("release-check:proof:not-analysed:" & To_String (Name));
            end if;
         end loop;

         if Unproved = 0 and then Legality = 0 and then Missing = 0 then
            --  Total from the summary's  Total  line, second field.
            declare
               Total : Unbounded_String;
               S     : Positive :=
                 (if Summary_C'Length = 0 then 1 else Summary_C'First);

               procedure Take_Total (Line : String) is
               begin
                  if Total = Null_Unbounded_String
                    and then Starts_With (Line, "Total")
                  then
                     declare
                        P : Integer := Line'First + 5;
                     begin
                        while P <= Line'Last and then Line (P) = ' ' loop
                           P := P + 1;
                        end loop;
                        declare
                           First : constant Integer := P;
                        begin
                           while P <= Line'Last and then Line (P) /= ' ' loop
                              P := P + 1;
                           end loop;
                           if First <= Line'Last then
                              Total := U (Line (First .. P - 1));
                           end if;
                        end;
                     end;
                  end if;
               end Take_Total;
            begin
               if Summary_C'Length > 0 then
                  for I in Summary_C'Range loop
                     if Summary_C (I) = LF then
                        Take_Total (Summary_C (S .. I - 1));
                        S := I + 1;
                     end if;
                  end loop;
                  if S <= Summary_C'Last then
                     Take_Total (Summary_C (S .. Summary_C'Last));
                  end if;
               end if;
               Record_Evidence
                 ("gnatprove", "passed",
                  "checks "
                  & (if Total = Null_Unbounded_String then "unknown"
                     else To_String (Total))
                  & " unproved 0");
            end;
         else
            Record_Evidence
              ("gnatprove", "failed",
               "unproved " & Img (Unproved) & " legality-errors "
               & Img (Legality) & " not-analysed " & Img (Missing));
            --  Echo up to 20 findings/legality lines (excluding cryptolib-).
            declare
               S     : Positive := (if Captured'Length = 0 then 1 else Captured'First);
               Shown : Natural := 0;

               procedure Consider (Line : String) is
               begin
                  if Shown < 20
                    and then not Starts_With (Line, "cryptolib-")
                    and then (Is_Finding (Line) or else Contains (Line, ": error: "))
                  then
                     Put_Line (Line);
                     Shown := Shown + 1;
                  end if;
               end Consider;
            begin
               if Captured'Length > 0 then
                  for I in Captured'Range loop
                     if Captured (I) = LF then
                        Consider (Captured (S .. I - 1));
                        S := I + 1;
                     end if;
                  end loop;
                  if S <= Captured'Last then
                     Consider (Captured (S .. Captured'Last));
                  end if;
               end if;
            end;
         end if;
      end;
   end if;

   ---------------------------------------------------------------------------
   --  identity_tools build
   ---------------------------------------------------------------------------
   Section ("identity_tools build");
   if Run_Cap (Root & "/crates/identity_tools", "alr build") /= 0 then
      Print_Tail (To_String (Last_Output), 20);
      Fatal ("release-check:identity_tools:failed:build");
   end if;

   ---------------------------------------------------------------------------
   --  gate self-tests build
   ---------------------------------------------------------------------------
   Section ("gate self-tests build");
   if Run_Cap (Root & "/crates/identity_gate_selftests", "alr build") /= 0 then
      Print_Tail (To_String (Last_Output), 20);
      Fatal ("release-check:gate-selftests:failed:build");
   end if;

   ---------------------------------------------------------------------------
   --  gate self-tests
   ---------------------------------------------------------------------------
   Section ("gate self-tests");
   declare
      Selftests : constant String :=
        Root & "/crates/identity_gate_selftests/bin/gate_selftests";
   begin
      if Files.File_Exists (Selftests) then
         declare
            RC  : constant Integer :=
              Run_Cap (Root, Processes.Shell_Quote (Selftests) & " "
                       & Processes.Shell_Quote (Root));
            Captured : constant String := To_String (Last_Output);
         begin
            if RC = 0 then
               Record_Evidence
                 ("gate-selftests", "passed",
                  Extract_Marker
                    (Captured, "gate-selftest:total:", Last => True, Strip => False));
            else
               Record_Evidence
                 ("gate-selftests", "failed",
                  "one or more gate self-tests failed");
               declare
                  Start : Positive := (if Captured'Length = 0 then 1 else Captured'First);
                  Shown : Natural := 0;

                  procedure Consider (Line : String) is
                  begin
                     if Shown < 20
                       and then (Contains (Line, "gate-selftest:FAIL")
                                 or else Contains (Line, "gate-selftest:error"))
                     then
                        Put_Line (Line);
                        Shown := Shown + 1;
                     end if;
                  end Consider;
               begin
                  if Captured'Length > 0 then
                     for I in Captured'Range loop
                        if Captured (I) = LF then
                           Consider (Captured (Start .. I - 1));
                           Start := I + 1;
                        end if;
                     end loop;
                     if Start <= Captured'Last then
                        Consider (Captured (Start .. Captured'Last));
                     end if;
                  end if;
               end;
            end if;
         end;
      else
         Record_Evidence
           ("gate-selftests", "failed",
            "gate_selftests tool missing or not executable");
      end if;
   end;

   ---------------------------------------------------------------------------
   --  identity_tools gates
   ---------------------------------------------------------------------------
   Section ("identity_tools gates");
   declare
      RC : constant Integer :=
        Processes.Run_Status
          (Label   => "identity_tools",
           Dir     => Root,
           Program => Root & "/crates/identity_tools/bin/identity_tools",
           Args    => Empty_Args,
           Quiet   => True);
   begin
      if RC = 0 then
         Put_Line ("release-check:identity_tools:passed");
      else
         Put_Line ("release-check:identity_tools:failed");
         Failed := True;
      end if;
   end;

   ---------------------------------------------------------------------------
   --  api surface
   ---------------------------------------------------------------------------
   Section ("api surface");
   declare
      Specs   : constant Str_Array := Api_Specs;
      Content : Unbounded_String;
   begin
      for Spec of Specs loop
         Append (Content, To_String (Spec) & LF);
      end loop;
      Files.Write_Raw_File (Release_Dir & "/api-surface.txt", To_String (Content));
      if Specs'Length > 0 then
         Put_Line
           ("release-check:api-surface:passed:" & Img (Specs'Length) & "-specs");
      else
         Put_Line ("release-check:api-surface:failed:no-specs");
         Failed := True;
      end if;
   end;

   ---------------------------------------------------------------------------
   --  source archive + hygiene
   ---------------------------------------------------------------------------
   Section ("source archive + hygiene");
   declare
      Build : constant String :=
        "tar -czf " & Processes.Shell_Quote (Archive) & " -C "
        & Processes.Shell_Quote (Root)
        & " --exclude='*/obj' --exclude='*/bin' --exclude='*/alire'"
        & " --exclude='*.tar.gz'"
        & " src crates registries tools docs generated/release"
        & " alire.toml README.md CHANGELOG.md SECURITY.md";
      RC : constant Integer := Run_Cap (Root, Build);
      pragma Unreferenced (RC);
   begin
      if not (Files.File_Exists (Archive) and then Read_File (Archive)'Length > 0)
      then
         Put_Line ("release-check:source-archive:failed:not-produced");
         Failed := True;
      else
         declare
            List_RC   : constant Integer :=
              Run_Cap (Root, "tar -tzf " & Processes.Shell_Quote (Archive));
            Listing   : constant String := To_String (Last_Output);
            Start     : Positive := (if Listing'Length = 0 then 1 else Listing'First);
            Bad       : Boolean := False;

            procedure Consider (Line : String) is
            begin
               if Prohibited_Line (Line) then
                  Bad := True;
               end if;
            end Consider;

            pragma Unreferenced (List_RC);
         begin
            if Listing'Length > 0 then
               for I in Listing'Range loop
                  if Listing (I) = LF then
                     Consider (Listing (Start .. I - 1));
                     Start := I + 1;
                  end if;
               end loop;
               if Start <= Listing'Last then
                  Consider (Listing (Start .. Listing'Last));
               end if;
            end if;
            if Bad then
               Put_Line ("release-check:source-archive:failed:prohibited-file");
               Failed := True;
            else
               Put_Line
                 ("release-check:source-archive:passed:"
                  & Img (Line_Count (Listing)) & "-entries");
            end if;
         end;
      end if;
   end;

   ---------------------------------------------------------------------------
   --  artifact digests
   ---------------------------------------------------------------------------
   Section ("artifact digests");
   declare
      Digests : constant String := Release_Dir & "/artifact-digests.txt";
      Content : Unbounded_String;
      Count   : Natural := 0;
   begin
      Append (Content, "digest-records:computed" & LF);
      Append (Content, "algorithm:sha256" & LF);
      for Name of Release_Txt_Files loop
         declare
            Path : constant String := Release_Dir & "/" & To_String (Name);
         begin
            if Files.File_Exists (Path) then
               Append
                 (Content, SHA256_Hex (Path) & "  " & To_String (Name) & LF);
               Count := Count + 1;
            end if;
         end;
      end loop;
      if Files.File_Exists (Archive) then
         Append
           (Content,
            SHA256_Hex (Archive) & "  " & Ada.Directories.Simple_Name (Archive)
            & LF);
         Count := Count + 1;
      end if;
      Files.Write_Raw_File (Digests, To_String (Content));
      if Count > 0 then
         Put_Line
           ("release-check:artifact-digests:passed:" & Img (Count) & "-digests");
      else
         Put_Line ("release-check:artifact-digests:failed:none-computed");
         Failed := True;
      end if;
   end;

   ---------------------------------------------------------------------------
   --  cryptolib self-tests
   ---------------------------------------------------------------------------
   Section ("cryptolib self-tests");
   declare
      Crypto_Tests : constant String := Root & "/../cryptolib/tests";
   begin
      if Files.File_Exists (Crypto_Tests & "/tests.gpr") then
         if Run_Cap (Crypto_Tests, "alr build") = 0
           and then Run_Cap (Crypto_Tests, "./bin/tests") = 0
         then
            Put_Line
              ("release-check:cryptolib-selftests:passed:"
               & Last_Line (To_String (Last_Output)));
         else
            Put_Line ("release-check:cryptolib-selftests:failed");
            Print_Tail (To_String (Last_Output), 10);
            Failed := True;
         end if;
      else
         Put_Line ("release-check:cryptolib-selftests:skipped:not-present");
      end if;
   end;

   ---------------------------------------------------------------------------
   --  Result
   ---------------------------------------------------------------------------
   if Failed then
      Put_Line ("release-check:result:failed");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Put_Line ("release-check:result:passed");
   end if;

exception
   when Halt =>
      null;
end Release_Check;
