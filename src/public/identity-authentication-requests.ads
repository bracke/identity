with Identity.Assurance.Profiles;
with Identity.Authentication.Contexts;
with Identity.Identities.Subjects;
with Identity.Identifiers.Registry;
with Identity.Sessions.Policies;

package Identity.Authentication.Requests is
   type Authentication_Request is record
      Subject : Identity.Identities.Subjects.Authentication_Subject;
      Credential_Input_Present : Boolean := False;
      Requested_Profile : Identity.Identifiers.Registry.Registry_Id :=
        Identity.Assurance.Profiles.Basic;
      Session_Request : Identity.Sessions.Policies.Session_Request_Kind :=
        Identity.Sessions.Policies.No_Session;
      Context : Identity.Authentication.Contexts.Authentication_Context;
   end record;

   function Bounded_And_Complete (Value : Authentication_Request) return Boolean is
     (Value.Credential_Input_Present
      and then Identity.Authentication.Contexts.Enumeration_Safe (Value.Context));
end Identity.Authentication.Requests;
