with Ada.Directories;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

with Project_Tools.Generated_Docs;
with Project_Tools.Text;

package body Identity_Tools_Facts is
   use Ada.Strings.Unbounded;

   Begin_Marker : constant String := "<!-- generated: identity-facts -->";
   End_Marker   : constant String := "<!-- end generated: identity-facts -->";

   function Resolve (Relative : String) return String is
     (if Ada.Directories.Exists (Relative) then Relative else "../../" & Relative);

   function Gates_Path return String is (Resolve ("tools/release-gates.txt"));

   function Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);
   end Image;

   function Rendered
     (Event_Types         : Natural;
      Mutating_Operations : Natural;
      Audited_Operations  : Natural;
      Exempt_Operations   : Natural;
      Audited_Overloads   : Natural;
      Bypass_Overloads    : Natural;
      Proved_Packages     : Natural;
      Invariants          : Natural;
      Test_Routines       : Natural) return String
   is
      Buffer : Unbounded_String;
      procedure Line (Text : String) is
      begin
         Append (Buffer, Text);
         Append (Buffer, ASCII.LF);
      end Line;
   begin
      Line (Begin_Marker);
      Line ("These figures are produced by identity_tools, not maintained by");
      Line ("hand. If the release check reports this block stale, paste the");
      Line ("text it prints -- do not edit the numbers to match.");
      Line ("");
      Line ("  event types                 " & Image (Event_Types));
      Line ("  mutating operations         " & Image (Mutating_Operations));
      Line ("  ..audited                   " & Image (Audited_Operations));
      Line ("  ..exempt (justified)        " & Image (Exempt_Operations));
      Line ("  audited overloads           " & Image (Audited_Overloads));
      Line ("  context-free overloads      " & Image (Bypass_Overloads));
      Line ("  proved packages             " & Image (Proved_Packages));
      Line ("  security invariants         " & Image (Invariants));
      Line ("  registered test routines    " & Image (Test_Routines));
      Append (Buffer, End_Marker);
      return To_String (Buffer);
   end Rendered;

   procedure Validate
     (Report              : out Validation_Report;
      Event_Types         : Natural;
      Mutating_Operations : Natural;
      Audited_Operations  : Natural;
      Exempt_Operations   : Natural;
      Audited_Overloads   : Natural;
      Bypass_Overloads    : Natural;
      Proved_Packages     : Natural;
      Invariants          : Natural;
      Test_Routines       : Natural)
   is
      Generated : constant String :=
        Rendered
          (Event_Types, Mutating_Operations, Audited_Operations,
           Exempt_Operations, Audited_Overloads, Bypass_Overloads,
           Proved_Packages, Invariants, Test_Routines);
      Errors : Natural := 0;
   begin
      Report := (others => 0);

      if not Ada.Directories.Exists (Gates_Path) then
         Report.Missing_Blocks := 1;
         Ada.Text_IO.Put_Line ("facts:missing-document:" & Gates_Path);
         return;
      end if;

      declare
         Document : constant String :=
           To_String (Project_Tools.Text.Read_Text_File (Gates_Path));
         From : constant Natural := Project_Tools.Text.Index (Document, Begin_Marker);
         To   : constant Natural := Project_Tools.Text.Index (Document, End_Marker);
      begin
         Report.Blocks_Checked := 1;

         if From = 0 or else To = 0 or else To < From then
            Report.Missing_Blocks := 1;
            Ada.Text_IO.Put_Line ("facts:missing-block:identity-facts");
            Ada.Text_IO.Put_Line ("facts:expected-block-begin");
            Ada.Text_IO.Put_Line (Generated);
            Ada.Text_IO.Put_Line ("facts:expected-block-end");
            return;
         end if;

         declare
            Stored : constant String :=
              Document (From .. To + End_Marker'Length - 1);
         begin
            Project_Tools.Generated_Docs.Require_Current
              (Errors    => Errors,
               Stored    => Stored,
               Generated => Generated,
               Message   => "facts:stale-block:identity-facts",
               Quiet     => False);
            if Errors > 0 then
               Report.Stale_Blocks := 1;
               Ada.Text_IO.Put_Line ("facts:expected-block-begin");
               Ada.Text_IO.Put_Line (Generated);
               Ada.Text_IO.Put_Line ("facts:expected-block-end");
            end if;
         end;
      end;
   end Validate;

   function Passed (Report : Validation_Report) return Boolean is
     (Report.Blocks_Checked > 0
      and then Report.Stale_Blocks = 0
      and then Report.Missing_Blocks = 0);

end Identity_Tools_Facts;
