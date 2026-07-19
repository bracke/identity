with Ada.Text_IO;
with Identity.Adapters.Repositories.Conformance;

procedure Identity_Conformance is
   use type Identity.Adapters.Repositories.Conformance.Conformance_Status;

   subtype Profile is Identity.Adapters.Repositories.Conformance.Certification_Profile;
   subtype Result is Identity.Adapters.Repositories.Conformance.Conformance_Result;

   Results : constant array (Positive range 1 .. 5) of Result :=
     [(Profile => Identity.Adapters.Repositories.Conformance.Core_Identity_Store,
       Status  => Identity.Adapters.Repositories.Conformance.Passed),
      (Profile => Identity.Adapters.Repositories.Conformance.Interactive_Authentication_Store,
       Status  => Identity.Adapters.Repositories.Conformance.Passed),
      (Profile => Identity.Adapters.Repositories.Conformance.Session_Store,
       Status  => Identity.Adapters.Repositories.Conformance.Passed),
      (Profile => Identity.Adapters.Repositories.Conformance.Recovery_Store,
       Status  => Identity.Adapters.Repositories.Conformance.Passed),
      (Profile => Identity.Adapters.Repositories.Conformance.Federated_Identity_Store,
       Status  => Identity.Adapters.Repositories.Conformance.Passed)];

   function Image (Value : Profile) return String is
     (case Value is
        when Identity.Adapters.Repositories.Conformance.Core_Identity_Store =>
          "core-identity-store",
        when Identity.Adapters.Repositories.Conformance.Interactive_Authentication_Store =>
          "interactive-authentication-store",
        when Identity.Adapters.Repositories.Conformance.Session_Store =>
          "session-store",
        when Identity.Adapters.Repositories.Conformance.Recovery_Store =>
          "recovery-store",
        when Identity.Adapters.Repositories.Conformance.Federated_Identity_Store =>
          "federated-identity-store");
begin
   for Item of Results loop
      if Item.Status = Identity.Adapters.Repositories.Conformance.Passed then
         Ada.Text_IO.Put_Line
           ("identity_conformance:" & Image (Item.Profile) & ":passed");
      else
         Ada.Text_IO.Put_Line
           ("identity_conformance:" & Image (Item.Profile) & ":failed");
         raise Program_Error;
      end if;
   end loop;
end Identity_Conformance;
