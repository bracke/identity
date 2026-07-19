package body Identity.Authentication.Security_Contexts is
   use type Identity.Versions.Authentication_State_Revision;
   use type Identity.Versions.Evidence_Revision;
   use type Identity.Versions.Session_Revision;

   function Instant_Recent
     (Instant     : Identity.Times.Instant;
      Now         : Identity.Times.Instant;
      Maximum_Age : Identity.Times.Durations.Authentication_Maximum_Age)
      return Boolean;

   function Anonymous_Context return Security_Context is
     ((State => Anonymous, Valid_Until => (Present => False)));

   function Current_Revisions (Context : Security_Context) return Revision_Baseline is
   begin
      case Context.State is
         when Anonymous =>
            return (Authentication => 0,
                    Evidence => 0,
                    Session => 0,
                    Session_Present => False);
         when Authenticated =>
            return
              (Authentication => Context.Authentication_Revision,
               Evidence => Context.Evidence_Revision,
               Session => Context.Session_Revision,
               Session_Present => Context.Session.Present);
      end case;
   end Current_Revisions;

   function Revision_Changed
     (Context : Security_Context;
      Current : Revision_Baseline) return Boolean is
   begin
      case Context.State is
         when Anonymous =>
            return False;
         when Authenticated =>
            return
              Context.Authentication_Revision /= Current.Authentication
              or else Context.Evidence_Revision /= Current.Evidence
              or else Context.Session.Present /= Current.Session_Present
              or else
                (Context.Session.Present
                 and then Context.Session_Revision /= Current.Session);
      end case;
   end Revision_Changed;

   function Has_Session (Context : Security_Context) return Boolean is
   begin
      return Context.State = Authenticated and then Context.Session.Present;
   end Has_Session;

   function Admission_Status
     (Context : Security_Context;
      Current : Revision_Baseline;
      Now     : Identity.Times.Instant) return Context_Admission_Status is
      use type Identity.Times.Instant;
   begin
      if Revision_Changed (Context, Current) then
         return Stale_Revisions;
      end if;

      case Context.State is
         when Anonymous =>
            if Context.Valid_Until.Present and then Now > Context.Valid_Until.Value then
               return Anonymous_Expired;
            end if;
            return Context_Usable;
         when Authenticated =>
            if not Context.Eligible then
               return Authenticated_Ineligible;
            end if;
            if Context.Validity_Boundary.Present
              and then Now > Context.Validity_Boundary.Value
            then
               return Authenticated_Expired;
            end if;
            return Context_Usable;
      end case;
   end Admission_Status;

   function Usable_For_Downstream
     (Context : Security_Context;
      Current : Revision_Baseline;
      Now     : Identity.Times.Instant) return Boolean is
   begin
      return Admission_Status (Context, Current, Now) = Context_Usable;
   end Usable_For_Downstream;

   function Instant_Recent
     (Instant     : Identity.Times.Instant;
      Now         : Identity.Times.Instant;
      Maximum_Age : Identity.Times.Durations.Authentication_Maximum_Age)
      return Boolean is
      use type Identity.Times.Instant;
      Boundary : Identity.Times.Instant;
      Ok       : Boolean;
   begin
      if Now < Instant then
         return False;
      end if;

      Boundary :=
        Identity.Times.Add
          (Instant,
           Identity.Times.Durations.To_Base (Maximum_Age),
           Ok);
      return Ok and then Now <= Boundary;
   end Instant_Recent;

   function Original_Authentication_Recent
     (Context     : Security_Context;
      Now         : Identity.Times.Instant;
      Maximum_Age : Identity.Times.Durations.Authentication_Maximum_Age)
      return Boolean is
   begin
      return
        Context.State = Authenticated
        and then Instant_Recent
          (Context.Original_Authenticated_At, Now, Maximum_Age);
   end Original_Authentication_Recent;

   function Primary_Authentication_Recent
     (Context     : Security_Context;
      Now         : Identity.Times.Instant;
      Maximum_Age : Identity.Times.Durations.Authentication_Maximum_Age)
      return Boolean is
   begin
      return
        Context.State = Authenticated
        and then Instant_Recent
          (Context.Primary_Authenticated_At, Now, Maximum_Age);
   end Primary_Authentication_Recent;

   function MFA_Completion_Recent
     (Context     : Security_Context;
      Now         : Identity.Times.Instant;
      Maximum_Age : Identity.Times.Durations.Authentication_Maximum_Age)
      return Boolean is
   begin
      return
        Context.State = Authenticated
        and then Context.MFA_Completed_At.Present
        and then Instant_Recent (Context.MFA_Completed_At.Value, Now, Maximum_Age);
   end MFA_Completion_Recent;

   function Step_Up_Recent
     (Context     : Security_Context;
      Now         : Identity.Times.Instant;
      Maximum_Age : Identity.Times.Durations.Authentication_Maximum_Age)
      return Boolean is
   begin
      return
        Context.State = Authenticated
        and then Context.Step_Up_At.Present
        and then Instant_Recent (Context.Step_Up_At.Value, Now, Maximum_Age);
   end Step_Up_Recent;
end Identity.Authentication.Security_Contexts;
