package Identity_Tools_Audit_Coverage is
   pragma Elaborate_Body;

   --  An operation that changes security state without leaving a record is a
   --  hole in the audit trail, and holes of that kind are invisible: the code
   --  compiles, the tests pass, and the question "who removed this factor?"
   --  simply has no answer.
   --
   --  This gate derives the set of mutating SPI primitives from the interface
   --  itself -- every primitive whose Repository parameter is "in out" -- and
   --  requires that any operation body calling one of them also emits an
   --  audit event. Deriving the set from the SPI rather than from a hand-kept
   --  list means a newly added mutating primitive is covered automatically.
   --  Note what "audited" means here. Emission was added as an ADDITIONAL
   --  overload on each operation so existing callers keep compiling, which
   --  means every audited operation still exposes plain overloads that mutate
   --  without emitting. The gate requires every mutating operation to OFFER an
   --  audited path; it cannot require callers to take it. Bypass_Overloads
   --  counts that remaining surface so the number is visible rather than
   --  implied away by a per-file "audited" count.
   type Validation_Report is record
      Mutating_Primitives : Natural := 0;
      Mutating_Operations : Natural := 0;
      Audited_Operations  : Natural := 0;
      Unaudited_Operations : Natural := 0;
      Audited_Overloads   : Natural := 0;
      Bypass_Overloads    : Natural := 0;
      Missing_Source      : Natural := 0;
   end record;

   procedure Validate (Report : out Validation_Report);
   function Passed (Report : Validation_Report) return Boolean;
end Identity_Tools_Audit_Coverage;
