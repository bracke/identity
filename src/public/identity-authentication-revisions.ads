with Identity.Versions;

package Identity.Authentication.Revisions is
   subtype Authentication_State_Revision is Identity.Versions.Authentication_State_Revision;
   subtype Evidence_Revision is Identity.Versions.Evidence_Revision;
   subtype Session_Revision is Identity.Versions.Session_Revision;
end Identity.Authentication.Revisions;
