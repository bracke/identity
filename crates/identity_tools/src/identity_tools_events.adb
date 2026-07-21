with Ada.Directories;
with Ada.Strings.Unbounded;
with Project_Tools.Text;
with Ada.Strings.Fixed;
with Ada.Text_IO;

package body Identity_Tools_Events is

   type Event_Id is
     (Authentication_Succeeded,
      Authentication_Rejected,
      Session_Created,
      Session_Rotated,
      Session_Revoked,
      Password_Changed,
      Password_Reset_Requested,
      Password_Reset_Completed,
      Account_Disabled,
      Contact_Verified,
      MFA_Challenge_Completed,
      Recovery_Completed,
      API_Key_Authenticated,
      API_Key_Revoked,
      TOTP_Replay_Detected,
      External_Assertion_Replay_Detected,
      Principal_Created,
      Principal_Retired,
      Account_Created,
      Account_Enabled,
      Account_Suspended,
      Account_Closed,
      Account_Unlocked,
      Account_MFA_Required,
      Account_Password_Change_Required,
      Password_Enrolled,
      API_Key_Issued,
      API_Key_Rotated,
      Authentication_Transaction_Began,
      MFA_Enrollment_Began,
      MFA_Factor_Enrolled,
      MFA_Factor_Removed,
      MFA_Challenge_Issued,
      Recovery_Codes_Generated,
      Recovery_Code_Consumed,
      Identity_Binding_Added,
      Identity_Binding_Changed,
      Identity_Binding_Revoked,
      External_Binding_Revoked,
      Token_Issued,
      Token_Consumed,
      Recovery_Began,
      Recovery_Continued,
      Recovery_Cancelled,
      Contact_Change_Began,
      Contact_Change_Advanced,
      Contact_Change_Completed,
      External_Binding_Created,
      Session_Expired,
      Session_Purged,
      Contact_Verification_Requested,
      Password_Verifier_Migrated,
      Session_Renewed,
      Session_Assurance_Upgraded,
      TOTP_Counter_Accepted);

   type Event_Presence is array (Event_Id) of Boolean;

   Expected_Count : constant Natural := Event_Id'Pos (Event_Id'Last) + 1;

   function Contains (Line : String; Pattern : String) return Boolean is
     (Ada.Strings.Fixed.Index (Line, Pattern) /= 0);

   function Registry_Path return String is
     (if Ada.Directories.Exists ("registries/event-types.json") then
        "registries/event-types.json"
      else
        "../../registries/event-types.json");

   function Public_Path return String is
     (if Ada.Directories.Exists ("src/public/identity-events-types.ads") then
        "src/public/identity-events-types.ads"
      else
        "../../src/public/identity-events-types.ads");

   function Image (Id : Event_Id) return String is
     (case Id is
        when Authentication_Succeeded =>
          "identity.authentication.succeeded",
        when Authentication_Rejected =>
          "identity.authentication.rejected",
        when Session_Created =>
          "identity.session.created",
        when Session_Rotated =>
          "identity.session.rotated",
        when Session_Revoked =>
          "identity.session.revoked",
        when Password_Changed =>
          "identity.password.changed",
        when Password_Reset_Requested =>
          "identity.password.reset.requested",
        when Password_Reset_Completed =>
          "identity.password.reset.completed",
        when Account_Disabled =>
          "identity.account.disabled",
        when Contact_Verified =>
          "identity.contact.verified",
        when MFA_Challenge_Completed =>
          "identity.mfa.challenge.completed",
        when Recovery_Completed =>
          "identity.recovery.completed",
        when API_Key_Authenticated =>
          "identity.api-key.authenticated",
        when API_Key_Revoked =>
          "identity.api-key.revoked",
        when TOTP_Replay_Detected =>
          "identity.totp.replay-detected",
        when External_Assertion_Replay_Detected =>
          "identity.external.assertion.replay-detected",
        when Principal_Created =>
          "identity.principal.created",
        when Principal_Retired =>
          "identity.principal.retired",
        when Account_Created =>
          "identity.account.created",
        when Account_Enabled =>
          "identity.account.enabled",
        when Account_Suspended =>
          "identity.account.suspended",
        when Account_Closed =>
          "identity.account.closed",
        when Account_Unlocked =>
          "identity.account.unlocked",
        when Account_MFA_Required =>
          "identity.account.mfa-required",
        when Account_Password_Change_Required =>
          "identity.account.password-change-required",
        when Password_Enrolled =>
          "identity.password.enrolled",
        when API_Key_Issued =>
          "identity.api-key.issued",
        when API_Key_Rotated =>
          "identity.api-key.rotated",
        when Authentication_Transaction_Began =>
          "identity.authentication.transaction.began",
        when MFA_Enrollment_Began =>
          "identity.mfa.factor.enrollment-began",
        when MFA_Factor_Enrolled =>
          "identity.mfa.factor.enrolled",
        when MFA_Factor_Removed =>
          "identity.mfa.factor.removed",
        when MFA_Challenge_Issued =>
          "identity.mfa.challenge.issued",
        when Recovery_Codes_Generated =>
          "identity.recovery-codes.generated",
        when Recovery_Code_Consumed =>
          "identity.recovery-code.consumed",
        when Identity_Binding_Added =>
          "identity.binding.added",
        when Identity_Binding_Changed =>
          "identity.binding.changed",
        when Identity_Binding_Revoked =>
          "identity.binding.revoked",
        when External_Binding_Revoked =>
          "identity.external.binding.revoked",
        when Token_Issued =>
          "identity.token.issued",
        when Token_Consumed =>
          "identity.token.consumed",
        when Recovery_Began =>
          "identity.recovery.began",
        when Recovery_Continued =>
          "identity.recovery.continued",
        when Recovery_Cancelled =>
          "identity.recovery.cancelled",
        when Contact_Change_Began =>
          "identity.contact.change.began",
        when Contact_Change_Advanced =>
          "identity.contact.change.advanced",
        when Contact_Change_Completed =>
          "identity.contact.change.completed",
        when External_Binding_Created =>
          "identity.external.binding.created",
        when Session_Expired =>
          "identity.session.expired",
        when Session_Purged =>
          "identity.session.purged",
        when Contact_Verification_Requested =>
          "identity.contact.verification.requested",
        when Password_Verifier_Migrated =>
          "identity.password.verifier.migrated",
        when Session_Renewed =>
          "identity.session.renewed",
        when Session_Assurance_Upgraded =>
          "identity.session.assurance-upgraded",
        when TOTP_Counter_Accepted =>
          "identity.totp.counter-accepted");

   procedure Scan
     (Path     : String;
      Presence : out Event_Presence;
      Count    : out Natural)
   is
      File : Ada.Text_IO.File_Type;
   begin
      Presence := [others => False];
      Count := 0;

      if not Ada.Directories.Exists (Path) then
         Ada.Text_IO.Put_Line ("events:missing-file:" & Path);
         return;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (File);
         begin
            for Id in Event_Id loop
               if Contains (Line, Image (Id)) then
                  if not Presence (Id) then
                     Count := Count + 1;
                  end if;
                  Presence (Id) := True;
               end if;
            end loop;
         end;
      end loop;
      Ada.Text_IO.Close (File);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Scan;

   procedure Validate (Report : out Validation_Report) is
      Registry_Presence : Event_Presence;
      Public_Presence   : Event_Presence;
   begin
      Report := (others => 0);
      Scan (Registry_Path, Registry_Presence, Report.Registry_Event_Count);

      --  Every quoted identity. value in the registry must be one this gate
      --  knows; anything else is an identifier with no public constant.
      declare
         Total : constant Natural :=
           Project_Tools.Text.Count
             (Ada.Strings.Unbounded.To_String
                (Project_Tools.Text.Read_Text_File (Registry_Path)),
              """identity.");
      begin
         if Total > Report.Registry_Event_Count then
            Report.Unknown_Registry_Entries :=
              Total - Report.Registry_Event_Count;
            Ada.Text_IO.Put_Line
              ("events:unknown-registry-entries:"
               & Natural'Image (Report.Unknown_Registry_Entries));
         end if;
      end;
      Scan (Public_Path, Public_Presence, Report.Public_Event_Count);

      for Id in Event_Id loop
         if Registry_Presence (Id) and then not Public_Presence (Id) then
            Report.Missing_Public := Report.Missing_Public + 1;
            Ada.Text_IO.Put_Line ("events:missing-public:" & Image (Id));
         end if;

         if Public_Presence (Id) and then not Registry_Presence (Id) then
            Report.Missing_Registry := Report.Missing_Registry + 1;
            Ada.Text_IO.Put_Line ("events:missing-registry:" & Image (Id));
         end if;
      end loop;
   end Validate;

   function Passed (Report : Validation_Report) return Boolean is
     (Report.Registry_Event_Count = Expected_Count
      and then Report.Public_Event_Count = Expected_Count
      and then Report.Missing_Public = 0
      and then Report.Missing_Registry = 0
      and then Report.Unknown_Registry_Entries = 0);

end Identity_Tools_Events;
