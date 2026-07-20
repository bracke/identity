with AUnit.Test_Cases;
with AUnit.Test_Suites;

--  The identity assertion suite, as registered AUnit test cases.
--
--  It was one straight-line procedure of 748 assertions: a failure reported
--  the AUnit library's own line number and said nothing about which check
--  broke. Each topical section is now a registered routine, so a failure is
--  attributed to a named test.
--
--  Registration order is preserved deliberately. The sections share one
--  repository that accumulates state, so they are ordered, not independent:
--  this buys named reporting, not isolation. Making them independent means
--  decoupling the objects declared at package-body level below, which is a
--  larger change than this one.
package Identity_Tests_Cases is
   type Test_Case is new AUnit.Test_Cases.Test_Case with null record;

   overriding procedure Register_Tests (T : in out Test_Case);
   overriding function Name (T : Test_Case) return AUnit.Message_String;

   function Suite return AUnit.Test_Suites.Access_Test_Suite;
end Identity_Tests_Cases;
