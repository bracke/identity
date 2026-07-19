with Identity.Projections.Sessions;
with Identity.Sessions.Definitions;

package Identity.Sessions.Projections is
   pragma Pure;

   subtype Session_Summary_Projection is
     Identity.Projections.Sessions.Session_Summary_Projection;
   subtype Session_Summary_List is
     Identity.Projections.Sessions.Session_Summary_List;

   Max_Session_Summaries : constant Natural :=
     Identity.Projections.Sessions.Max_Session_Summaries;

   function Summary
     (Session : Identity.Sessions.Definitions.Session_Record)
      return Session_Summary_Projection renames Identity.Projections.Sessions.Summary;
end Identity.Sessions.Projections;
