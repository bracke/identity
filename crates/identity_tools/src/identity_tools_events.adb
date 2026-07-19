with Ada.Directories;
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
      External_Assertion_Replay_Detected);

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
          "identity.external.assertion.replay-detected");

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
      and then Report.Missing_Registry = 0);

end Identity_Tools_Events;
