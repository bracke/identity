package body Identity.Sessions.Assurance is
   function Satisfies
     (Session : Identity.Sessions.Definitions.Session_Record;
      Minimum : Identity.Assurance.Levels.Assurance_Level) return Boolean
   is
      use type Identity.Assurance.Levels.Assurance_Level;
   begin
      return Session.Assurance >= Minimum;
   end Satisfies;
end Identity.Sessions.Assurance;
