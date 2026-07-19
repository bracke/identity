with Identity.Assurance.Levels;
with Identity.Sessions.Definitions;

package Identity.Sessions.Assurance is
   pragma Pure;

   function Satisfies
     (Session : Identity.Sessions.Definitions.Session_Record;
      Minimum : Identity.Assurance.Levels.Assurance_Level) return Boolean;
end Identity.Sessions.Assurance;
