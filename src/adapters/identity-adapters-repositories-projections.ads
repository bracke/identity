with Identity.Projections.Accounts;
with Identity.Projections.Sessions;

package Identity.Adapters.Repositories.Projections is
   pragma Pure;

   subtype Account_State_Projection is
     Identity.Projections.Accounts.Account_State_Projection;
   subtype Session_Summary_Projection is
     Identity.Projections.Sessions.Session_Summary_Projection;
end Identity.Adapters.Repositories.Projections;
