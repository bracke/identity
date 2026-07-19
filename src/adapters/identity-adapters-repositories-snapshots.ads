with Identity.Accounts.Definitions;
with Identity.Identities.Resolution;
with Identity.Passwords.Credentials;
with Identity.Times;

package Identity.Adapters.Repositories.Snapshots is
   pragma Pure;

   type Optional_Account (Present : Boolean := False) is record
      case Present is
         when True =>
            Value : Identity.Accounts.Definitions.Account_Record;
         when False =>
            null;
      end case;
   end record;

   type Optional_Password (Present : Boolean := False) is record
      case Present is
         when True =>
            Value : Identity.Passwords.Credentials.Password_Credential_Record;
         when False =>
            null;
      end case;
   end record;

   type Authentication_Snapshot is record
      Resolution  : Identity.Identities.Resolution.Resolution_Result;
      Account     : Optional_Account;
      Credential  : Optional_Password;
      Snapshot_At : Identity.Times.Instant := 0;
   end record;
end Identity.Adapters.Repositories.Snapshots;
