package body Identity.Adapters.Repositories.Recording is
   function Call_Count (Repository : Store) return Natural is (Repository.Calls);

   function Total_Call_Count (Repository : Store) return Natural is (Repository.Total);

   overriding procedure Reset (Repository : in out Store)
   is
   begin
      Repository.Calls := 0;
      Stores.Reset (Repository.Inner.all);
   end Reset;

   overriding function Capabilities (Repository : Store)
      return Identity.Adapters.Repositories.Capabilities.Repository_Capabilities
   is
   begin
      return Stores.Capabilities (Repository.Inner.all);
   end Capabilities;

   overriding function Create_Principal
     (Repository : in out Store;
      Principal  : Identity.Principals.Definitions.Principal_Record) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Create_Principal (Repository.Inner.all, Principal);
   end Create_Principal;

   overriding function Retire_Principal
     (Repository : in out Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Retire_Principal (Repository.Inner.all, Principal);
   end Retire_Principal;

   overriding function Retire_Principal
     (Repository       : in out Store;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Expected_Version : Identity.Versions.Entity_Version) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Retire_Principal (Repository.Inner.all, Principal, Expected_Version);
   end Retire_Principal;

   overriding function Create_Account
     (Repository : in out Store;
      Account    : Identity.Accounts.Definitions.Account_Record) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Create_Account (Repository.Inner.all, Account);
   end Create_Account;

   overriding function Update_Account_State
     (Repository : in out Store;
      Account    : Identity.Identifiers.Entities.Account_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      State      : Identity.Accounts.States.Account_State_View)
      return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Update_Account_State (Repository.Inner.all, Account, Principal, State);
   end Update_Account_State;

   overriding function Add_Binding
     (Repository : in out Store;
      Binding    : Identity.Identities.Bindings.Binding_Record) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Add_Binding (Repository.Inner.all, Binding);
   end Add_Binding;

   overriding function Revoke_Binding
     (Repository : in out Store;
      Binding    : Identity.Identifiers.Entities.Identity_Binding_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Revoke_Binding (Repository.Inner.all, Binding, Principal);
   end Revoke_Binding;

   overriding function Revoke_Binding
     (Repository               : in out Store;
      Binding                  : Identity.Identifiers.Entities.Identity_Binding_Id;
      Principal                : Identity.Identifiers.Entities.Principal_Id;
      Expected_Binding_Version : Identity.Versions.Entity_Version) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Revoke_Binding (Repository.Inner.all, Binding, Principal, Expected_Binding_Version);
   end Revoke_Binding;

   overriding function Change_Binding
     (Repository  : in out Store;
      Predecessor : Identity.Identifiers.Entities.Identity_Binding_Id;
      Successor   : Identity.Identities.Bindings.Binding_Record) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Change_Binding (Repository.Inner.all, Predecessor, Successor);
   end Change_Binding;

   overriding function Change_Binding
     (Repository                   : in out Store;
      Predecessor                  : Identity.Identifiers.Entities.Identity_Binding_Id;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Successor                    : Identity.Identities.Bindings.Binding_Record) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Change_Binding (Repository.Inner.all, Predecessor, Expected_Predecessor_Version, Successor);
   end Change_Binding;

   overriding function Enroll_Password
     (Repository : in out Store;
      Credential : Identity.Passwords.Credentials.Password_Credential_Record) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Enroll_Password (Repository.Inner.all, Credential);
   end Enroll_Password;

   overriding function Replace_Password
     (Repository  : in out Store;
      Predecessor : Identity.Identifiers.Entities.Credential_Id;
      Successor   : Identity.Passwords.Credentials.Password_Credential_Record)
      return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Replace_Password (Repository.Inner.all, Predecessor, Successor);
   end Replace_Password;

   overriding function Replace_Password
     (Repository                   : in out Store;
      Predecessor                  : Identity.Identifiers.Entities.Credential_Id;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Successor                    : Identity.Passwords.Credentials.Password_Credential_Record)
      return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Replace_Password (Repository.Inner.all, Predecessor, Expected_Predecessor_Version, Successor);
   end Replace_Password;

   overriding function Create_Session
     (Repository : in out Store;
      Session    : Identity.Sessions.Definitions.Session_Record) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Create_Session (Repository.Inner.all, Session);
   end Create_Session;

   overriding procedure Find_Session
     (Repository : Store;
      Session    : Identity.Identifiers.Entities.Session_Id;
      Found      : out Boolean;
      Value      : out Identity.Sessions.Definitions.Session_Record)
   is
   begin
      Stores.Find_Session (Repository.Inner.all, Session, Found, Value);
   end Find_Session;

   overriding function Revoke_Session
     (Repository : in out Store;
      Session    : Identity.Identifiers.Entities.Session_Id) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Revoke_Session (Repository.Inner.all, Session);
   end Revoke_Session;

   overriding function Revoke_Session
     (Repository               : in out Store;
      Session                  : Identity.Identifiers.Entities.Session_Id;
      Expected_Session_Version : Identity.Versions.Entity_Version) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Revoke_Session (Repository.Inner.all, Session, Expected_Session_Version);
   end Revoke_Session;

   overriding function Rotate_Session
     (Repository  : in out Store;
      Predecessor : Identity.Identifiers.Entities.Session_Id;
      Successor   : Identity.Sessions.Definitions.Session_Record) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Rotate_Session (Repository.Inner.all, Predecessor, Successor);
   end Rotate_Session;

   overriding function Rotate_Session
     (Repository                   : in out Store;
      Predecessor                  : Identity.Identifiers.Entities.Session_Id;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Successor                    : Identity.Sessions.Definitions.Session_Record) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Rotate_Session (Repository.Inner.all, Predecessor, Expected_Predecessor_Version, Successor);
   end Rotate_Session;

   overriding function Revoke_Session_Family
     (Repository : in out Store;
      Family     : Identity.Identifiers.Entities.Session_Family_Id) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Revoke_Session_Family (Repository.Inner.all, Family);
   end Revoke_Session_Family;

   overriding function Revoke_Session_Family
     (Repository              : in out Store;
      Family                  : Identity.Identifiers.Entities.Session_Family_Id;
      Expected_Affected_Count : Natural) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Revoke_Session_Family (Repository.Inner.all, Family, Expected_Affected_Count);
   end Revoke_Session_Family;

   overriding function Revoke_Principal_Sessions
     (Repository : in out Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Revoke_Principal_Sessions (Repository.Inner.all, Principal);
   end Revoke_Principal_Sessions;

   overriding function Revoke_Principal_Sessions
     (Repository              : in out Store;
      Principal               : Identity.Identifiers.Entities.Principal_Id;
      Expected_Affected_Count : Natural) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Revoke_Principal_Sessions (Repository.Inner.all, Principal, Expected_Affected_Count);
   end Revoke_Principal_Sessions;

   overriding function Revoke_Credential_Sessions
     (Repository : in out Store;
      Credential : Identity.Identifiers.Entities.Credential_Id) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Revoke_Credential_Sessions (Repository.Inner.all, Credential);
   end Revoke_Credential_Sessions;

   overriding function Revoke_Credential_Sessions
     (Repository              : in out Store;
      Credential              : Identity.Identifiers.Entities.Credential_Id;
      Expected_Affected_Count : Natural) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Revoke_Credential_Sessions (Repository.Inner.all, Credential, Expected_Affected_Count);
   end Revoke_Credential_Sessions;

   overriding function Revoke_Provider_Sessions
     (Repository : in out Store;
      Provider   : Identity.Identifiers.Entities.External_Provider_Id) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Revoke_Provider_Sessions (Repository.Inner.all, Provider);
   end Revoke_Provider_Sessions;

   overriding function Revoke_Provider_Sessions
     (Repository              : in out Store;
      Provider                : Identity.Identifiers.Entities.External_Provider_Id;
      Expected_Affected_Count : Natural) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Revoke_Provider_Sessions (Repository.Inner.all, Provider, Expected_Affected_Count);
   end Revoke_Provider_Sessions;

   overriding function Expire_Eligible_Sessions
     (Repository : in out Store;
      Now        : Identity.Times.Instant) return Natural
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Expire_Eligible_Sessions (Repository.Inner.all, Now);
   end Expire_Eligible_Sessions;

   overriding function Purge_Retained_Sessions
     (Repository : in out Store;
      Retain_After : Identity.Times.Instant) return Natural
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Purge_Retained_Sessions (Repository.Inner.all, Retain_After);
   end Purge_Retained_Sessions;

   overriding function Enumerate_Principal_Sessions
     (Repository : Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Projections.Sessions.Session_Summary_List
   is
   begin
      return Stores.Enumerate_Principal_Sessions (Repository.Inner.all, Principal);
   end Enumerate_Principal_Sessions;

   overriding function Issue_Token
     (Repository : in out Store;
      Token      : Identity.Tokens.Definitions.Action_Token_Record) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Issue_Token (Repository.Inner.all, Token);
   end Issue_Token;

   overriding procedure Find_Token
     (Repository : Store;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Found      : out Boolean;
      Value      : out Identity.Tokens.Definitions.Action_Token_Record)
   is
   begin
      Stores.Find_Token (Repository.Inner.all, Token, Found, Value);
   end Find_Token;

   overriding function Begin_Authentication_Transaction
     (Repository  : in out Store;
      Transaction : Identity.Authentication.Transactions.Authentication_Transaction_Record)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Begin_Authentication_Transaction (Repository.Inner.all, Transaction);
   end Begin_Authentication_Transaction;

   overriding function Issue_Challenge
     (Repository : in out Store;
      Challenge  : Identity.Authentication.Challenges.Challenge_Record)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Issue_Challenge (Repository.Inner.all, Challenge);
   end Issue_Challenge;

   overriding function Issue_Challenge
     (Repository                   : in out Store;
      Challenge                    : Identity.Authentication.Challenges.Challenge_Record;
      Expected_Transaction_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Issue_Challenge (Repository.Inner.all, Challenge, Expected_Transaction_Version);
   end Issue_Challenge;

   overriding function Complete_Challenge
     (Repository : in out Store;
      Challenge  : Identity.Identifiers.Entities.Challenge_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Now        : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Complete_Challenge (Repository.Inner.all, Challenge, Principal, Now);
   end Complete_Challenge;

   overriding function Complete_Challenge
     (Repository                   : in out Store;
      Challenge                    : Identity.Identifiers.Entities.Challenge_Id;
      Principal                    : Identity.Identifiers.Entities.Principal_Id;
      Now                          : Identity.Times.Instant;
      Expected_Challenge_Version   : Identity.Versions.Entity_Version;
      Expected_Transaction_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Complete_Challenge
        (Repository.Inner.all,
         Challenge,
         Principal,
         Now,
         Expected_Challenge_Version,
         Expected_Transaction_Version);
   end Complete_Challenge;

   overriding function Satisfy_Authentication_Transaction
     (Repository  : in out Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Satisfy_Authentication_Transaction (Repository.Inner.all, Transaction, Principal, Now);
   end Satisfy_Authentication_Transaction;

   overriding function Satisfy_Authentication_Transaction
     (Repository          : in out Store;
      Transaction         : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal           : Identity.Identifiers.Entities.Principal_Id;
      Now                 : Identity.Times.Instant;
      Expected_Version    : Identity.Versions.Entity_Version)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Satisfy_Authentication_Transaction
        (Repository.Inner.all,
         Transaction,
         Principal,
         Now,
         Expected_Version);
   end Satisfy_Authentication_Transaction;

   overriding function Upgrade_Session_Assurance
     (Repository  : in out Store;
      Session     : Identity.Identifiers.Entities.Session_Id;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant;
      Assurance   : Identity.Assurance.Levels.Assurance_Level;
      Attributes  : Identity.Assurance.Attributes.Assurance_Attributes)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Upgrade_Session_Assurance
        (Repository.Inner.all,
         Session,
         Transaction,
         Principal,
         Now,
         Assurance,
         Attributes);
   end Upgrade_Session_Assurance;

   overriding function Upgrade_Session_Assurance
     (Repository                   : in out Store;
      Session                      : Identity.Identifiers.Entities.Session_Id;
      Transaction                  : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal                    : Identity.Identifiers.Entities.Principal_Id;
      Now                          : Identity.Times.Instant;
      Assurance                    : Identity.Assurance.Levels.Assurance_Level;
      Attributes                   : Identity.Assurance.Attributes.Assurance_Attributes;
      Expected_Session_Version     : Identity.Versions.Entity_Version;
      Expected_Transaction_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Upgrade_Session_Assurance
        (Repository.Inner.all,
         Session,
         Transaction,
         Principal,
         Now,
         Assurance,
         Attributes,
         Expected_Session_Version,
         Expected_Transaction_Version);
   end Upgrade_Session_Assurance;

   overriding procedure Find_Authentication_Transaction
     (Repository  : Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Found       : out Boolean;
      Value       : out Identity.Authentication.Transactions.Authentication_Transaction_Record)
   is
   begin
      Stores.Find_Authentication_Transaction (Repository.Inner.all, Transaction, Found, Value);
   end Find_Authentication_Transaction;

   overriding procedure Find_Challenge
     (Repository : Store;
      Challenge  : Identity.Identifiers.Entities.Challenge_Id;
      Found      : out Boolean;
      Value      : out Identity.Authentication.Challenges.Challenge_Record)
   is
   begin
      Stores.Find_Challenge (Repository.Inner.all, Challenge, Found, Value);
   end Find_Challenge;

   overriding function Issue_API_Key
     (Repository : in out Store;
      Credential : Identity.API_Keys.Credentials.API_Key_Credential_Record) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Issue_API_Key (Repository.Inner.all, Credential);
   end Issue_API_Key;

   overriding function Revoke_API_Key
     (Repository : in out Store;
      Credential : Identity.Identifiers.Entities.Credential_Id) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Revoke_API_Key (Repository.Inner.all, Credential);
   end Revoke_API_Key;

   overriding function Revoke_API_Key
     (Repository                  : in out Store;
      Credential                  : Identity.Identifiers.Entities.Credential_Id;
      Expected_Credential_Version : Identity.Versions.Entity_Version) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Revoke_API_Key (Repository.Inner.all, Credential, Expected_Credential_Version);
   end Revoke_API_Key;

   overriding function Rotate_API_Key
     (Repository  : in out Store;
      Predecessor : Identity.Identifiers.Entities.Credential_Id;
      Successor   : Identity.API_Keys.Credentials.API_Key_Credential_Record)
      return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Rotate_API_Key (Repository.Inner.all, Predecessor, Successor);
   end Rotate_API_Key;

   overriding function Rotate_API_Key
     (Repository                   : in out Store;
      Predecessor                  : Identity.Identifiers.Entities.Credential_Id;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Successor                    : Identity.API_Keys.Credentials.API_Key_Credential_Record)
      return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Rotate_API_Key (Repository.Inner.all, Predecessor, Expected_Predecessor_Version, Successor);
   end Rotate_API_Key;

   overriding procedure Find_API_Key
     (Repository : Store;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Found      : out Boolean;
      Value      : out Identity.API_Keys.Credentials.API_Key_Credential_Record)
   is
   begin
      Stores.Find_API_Key (Repository.Inner.all, Credential, Found, Value);
   end Find_API_Key;

   overriding function Event_Capacity_Available
     (Repository : Store;
      Count      : Positive) return Boolean
   is
   begin
      return Stores.Event_Capacity_Available (Repository.Inner.all, Count);
   end Event_Capacity_Available;

   overriding function Append_Event
     (Repository : in out Store;
      Event      : Identity.Events.Envelopes.Event_Envelope) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Append_Event (Repository.Inner.all, Event);
   end Append_Event;

   overriding function Record_Attempt
     (Repository : in out Store;
      Attempt    : Identity.Attempts.Definitions.Attempt_Record) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Record_Attempt (Repository.Inner.all, Attempt);
   end Record_Attempt;

   overriding procedure Find_Attempt
     (Repository : Store;
      Attempt    : Identity.Identifiers.Entities.Attempt_Id;
      Found      : out Boolean;
      Value      : out Identity.Attempts.Definitions.Attempt_Record)
   is
   begin
      Stores.Find_Attempt (Repository.Inner.all, Attempt, Found, Value);
   end Find_Attempt;

   overriding function Request_Contact_Verification
     (Repository : in out Store;
      Contact    : Identity.Contacts.Bindings.Contact_Binding_Record;
      Token      : Identity.Tokens.Definitions.Action_Token_Record) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Request_Contact_Verification (Repository.Inner.all, Contact, Token);
   end Request_Contact_Verification;

   overriding function Complete_Contact_Verification
     (Repository : in out Store;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Secret     : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now        : Identity.Times.Instant;
      Contact    : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Complete_Contact_Verification (Repository.Inner.all, Token, Secret, Now, Contact);
   end Complete_Contact_Verification;

   overriding function Complete_Contact_Verification
     (Repository               : in out Store;
      Token                    : Identity.Identifiers.Entities.Token_Id;
      Expected_Token_Version   : Identity.Versions.Entity_Version;
      Expected_Contact_Version : Identity.Versions.Entity_Version;
      Secret                   : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now                      : Identity.Times.Instant;
      Contact                  : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Complete_Contact_Verification
        (Repository.Inner.all,
         Token,
         Expected_Token_Version,
         Expected_Contact_Version,
         Secret,
         Now,
         Contact);
   end Complete_Contact_Verification;

   overriding function Begin_Contact_Change
     (Repository : in out Store;
      Change     : Identity.Verification.Changes.Contact_Change_Record;
      Successor  : Identity.Contacts.Bindings.Contact_Binding_Record;
      Token      : Identity.Tokens.Definitions.Action_Token_Record) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Begin_Contact_Change (Repository.Inner.all, Change, Successor, Token);
   end Begin_Contact_Change;

   overriding function Complete_Contact_Change
     (Repository  : in out Store;
      Token       : Identity.Identifiers.Entities.Token_Id;
      Secret      : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now         : Identity.Times.Instant;
      Predecessor : Identity.Identifiers.Entities.Contact_Binding_Id;
      Successor   : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Complete_Contact_Change (Repository.Inner.all, Token, Secret, Now, Predecessor, Successor);
   end Complete_Contact_Change;

   overriding function Complete_Contact_Change
     (Repository                   : in out Store;
      Token                        : Identity.Identifiers.Entities.Token_Id;
      Expected_Token_Version       : Identity.Versions.Entity_Version;
      Expected_Change_Version      : Identity.Versions.Entity_Version;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Expected_Successor_Version   : Identity.Versions.Entity_Version;
      Secret                       : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now                          : Identity.Times.Instant;
      Predecessor                  : Identity.Identifiers.Entities.Contact_Binding_Id;
      Successor                    : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Complete_Contact_Change
        (Repository.Inner.all,
         Token,
         Expected_Token_Version,
         Expected_Change_Version,
         Expected_Predecessor_Version,
         Expected_Successor_Version,
         Secret,
         Now,
         Predecessor,
         Successor);
   end Complete_Contact_Change;

   overriding procedure Find_Contact_Binding
     (Repository : Store;
      Contact    : Identity.Identifiers.Entities.Contact_Binding_Id;
      Found      : out Boolean;
      Value      : out Identity.Contacts.Bindings.Contact_Binding_Record)
   is
   begin
      Stores.Find_Contact_Binding (Repository.Inner.all, Contact, Found, Value);
   end Find_Contact_Binding;

   overriding function Install_Recovery_Code_Set
     (Repository : in out Store;
      Codes      : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Install_Recovery_Code_Set (Repository.Inner.all, Codes);
   end Install_Recovery_Code_Set;

   overriding function Regenerate_Recovery_Code_Set
     (Repository : in out Store;
      Codes      : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Regenerate_Recovery_Code_Set (Repository.Inner.all, Codes);
   end Regenerate_Recovery_Code_Set;

   overriding function Regenerate_Recovery_Code_Set
     (Repository              : in out Store;
      Codes                   : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record;
      Expected_Affected_Count : Natural) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Regenerate_Recovery_Code_Set (Repository.Inner.all, Codes, Expected_Affected_Count);
   end Regenerate_Recovery_Code_Set;

   overriding procedure Find_Recovery_Code_Set
     (Repository : Store;
      Set_Id     : Identity.Identifiers.Entities.Credential_Set_Id;
      Found      : out Boolean;
      Value      : out Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record)
   is
   begin
      Stores.Find_Recovery_Code_Set (Repository.Inner.all, Set_Id, Found, Value);
   end Find_Recovery_Code_Set;

   overriding function Begin_Recovery
     (Repository  : in out Store;
      Transaction : Identity.Recovery.Transactions.Recovery_Transaction_Record)
      return Identity.Recovery.Transactions.Recovery_Transition_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Begin_Recovery (Repository.Inner.all, Transaction);
   end Begin_Recovery;

   overriding function Accept_Recovery_Evidence
     (Repository  : in out Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant)
      return Identity.Recovery.Transactions.Recovery_Transition_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Accept_Recovery_Evidence (Repository.Inner.all, Transaction, Principal, Now);
   end Accept_Recovery_Evidence;

   overriding function Accept_Recovery_Evidence
     (Repository       : in out Store;
      Transaction      : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Now              : Identity.Times.Instant;
      Expected_Version : Identity.Versions.Entity_Version)
      return Identity.Recovery.Transactions.Recovery_Transition_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Accept_Recovery_Evidence (Repository.Inner.all, Transaction, Principal, Now, Expected_Version);
   end Accept_Recovery_Evidence;

   overriding function Complete_Recovery
     (Repository  : in out Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant)
      return Identity.Recovery.Transactions.Recovery_Transition_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Complete_Recovery (Repository.Inner.all, Transaction, Principal, Now);
   end Complete_Recovery;

   overriding function Complete_Recovery
     (Repository                   : in out Store;
      Transaction                  : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal                    : Identity.Identifiers.Entities.Principal_Id;
      Now                          : Identity.Times.Instant;
      Expected_Transaction_Version : Identity.Versions.Entity_Version;
      Expected_Account_Version     : Identity.Versions.Entity_Version)
      return Identity.Recovery.Transactions.Recovery_Transition_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Complete_Recovery
        (Repository.Inner.all,
         Transaction,
         Principal,
         Now,
         Expected_Transaction_Version,
         Expected_Account_Version);
   end Complete_Recovery;

   overriding function Cancel_Recovery
     (Repository  : in out Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Recovery.Transactions.Recovery_Transition_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Cancel_Recovery (Repository.Inner.all, Transaction, Principal);
   end Cancel_Recovery;

   overriding function Cancel_Recovery
     (Repository       : in out Store;
      Transaction      : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Expected_Version : Identity.Versions.Entity_Version)
      return Identity.Recovery.Transactions.Recovery_Transition_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Cancel_Recovery (Repository.Inner.all, Transaction, Principal, Expected_Version);
   end Cancel_Recovery;

   overriding function Advance_Recovery
     (Repository       : in out Store;
      Transaction      : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Action           : Identity.Recovery.Transactions.Recovery_Transaction_Action;
      Now              : Identity.Times.Instant;
      Expected_Version : Identity.Versions.Entity_Version)
      return Identity.Recovery.Transactions.Recovery_Transition_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Advance_Recovery
        (Repository.Inner.all, Transaction, Principal, Action, Now, Expected_Version);
   end Advance_Recovery;

   overriding procedure Find_Recovery_Transaction
     (Repository  : Store;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Found       : out Boolean;
      Value       : out Identity.Recovery.Transactions.Recovery_Transaction_Record)
   is
   begin
      Stores.Find_Recovery_Transaction (Repository.Inner.all, Transaction, Found, Value);
   end Find_Recovery_Transaction;

   overriding function Bind_External
     (Repository : in out Store;
      Binding    : Identity.External_Providers.Bindings.External_Binding_Record) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Bind_External (Repository.Inner.all, Binding);
   end Bind_External;

   overriding function Revoke_External
     (Repository : in out Store;
      Binding    : Identity.Identifiers.Entities.External_Binding_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Revoke_External (Repository.Inner.all, Binding, Principal);
   end Revoke_External;

   overriding function Revoke_External
     (Repository               : in out Store;
      Binding                  : Identity.Identifiers.Entities.External_Binding_Id;
      Principal                : Identity.Identifiers.Entities.Principal_Id;
      Expected_Binding_Version : Identity.Versions.Entity_Version) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Revoke_External (Repository.Inner.all, Binding, Principal, Expected_Binding_Version);
   end Revoke_External;

   overriding function External_Replay_Registered
     (Repository  : Store;
      Fingerprint : Identity.Text.Bounded.Bounded_Text) return Boolean
   is
   begin
      return Stores.External_Replay_Registered (Repository.Inner.all, Fingerprint);
   end External_Replay_Registered;

   overriding function Register_External_Replay
     (Repository  : in out Store;
      Fingerprint : Identity.Text.Bounded.Bounded_Text) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Register_External_Replay (Repository.Inner.all, Fingerprint);
   end Register_External_Replay;

   overriding function Reserve_Idempotency
     (Repository : in out Store;
      Operation  : Identity.Operations.Idempotency.Idempotent_Operation_Kind;
      Key        : Identity.Operations.Idempotency.Idempotency_Key)
      return Identity.Adapters.Repositories.Idempotency.Reservation
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Reserve_Idempotency (Repository.Inner.all, Operation, Key);
   end Reserve_Idempotency;

   overriding function Complete_Idempotency
     (Repository : in out Store;
      Operation  : Identity.Operations.Idempotency.Idempotent_Operation_Kind;
      Key        : Identity.Operations.Idempotency.Idempotency_Key)
      return Identity.Adapters.Repositories.Idempotency.Reservation
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Complete_Idempotency (Repository.Inner.all, Operation, Key);
   end Complete_Idempotency;

   overriding function Complete_Idempotency
     (Repository       : in out Store;
      Operation        : Identity.Operations.Idempotency.Idempotent_Operation_Kind;
      Key              : Identity.Operations.Idempotency.Idempotency_Key;
      Expected_Version : Identity.Versions.Entity_Version)
      return Identity.Adapters.Repositories.Idempotency.Reservation
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Complete_Idempotency (Repository.Inner.all, Operation, Key, Expected_Version);
   end Complete_Idempotency;

   overriding function Begin_TOTP_Enrollment
     (Repository : in out Store;
      Credential : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record)
      return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Begin_TOTP_Enrollment (Repository.Inner.all, Credential);
   end Begin_TOTP_Enrollment;

   overriding function Complete_TOTP_Enrollment
     (Repository : in out Store;
      Credential : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record)
      return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Complete_TOTP_Enrollment (Repository.Inner.all, Credential);
   end Complete_TOTP_Enrollment;

   overriding function Complete_TOTP_Enrollment
     (Repository                  : in out Store;
      Credential                  : Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record;
      Expected_Credential_Version : Identity.Versions.Entity_Version)
      return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Complete_TOTP_Enrollment (Repository.Inner.all, Credential, Expected_Credential_Version);
   end Complete_TOTP_Enrollment;

   overriding procedure Find_TOTP_Credential
     (Repository : Store;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Found      : out Boolean;
      Value      : out Identity.One_Time_Passwords.Credentials.TOTP_Credential_Record)
   is
   begin
      Stores.Find_TOTP_Credential (Repository.Inner.all, Credential, Found, Value);
   end Find_TOTP_Credential;

   overriding function Remove_TOTP
     (Repository : in out Store;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Remove_TOTP (Repository.Inner.all, Credential, Principal);
   end Remove_TOTP;

   overriding function Remove_TOTP
     (Repository                  : in out Store;
      Credential                  : Identity.Identifiers.Entities.Credential_Id;
      Principal                   : Identity.Identifiers.Entities.Principal_Id;
      Expected_Credential_Version : Identity.Versions.Entity_Version) return Stores.Command_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Remove_TOTP (Repository.Inner.all, Credential, Principal, Expected_Credential_Version);
   end Remove_TOTP;

   overriding function Resolve
     (Repository : Store;
      Subject    : Identity.Identities.Subjects.Authentication_Subject)
      return Identity.Identities.Resolution.Resolution_Result
   is
   begin
      return Stores.Resolve (Repository.Inner.all, Subject);
   end Resolve;

   overriding procedure Find_Active_Password
     (Repository : Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Found      : out Boolean;
      Credential : out Identity.Passwords.Credentials.Password_Credential_Record)
   is
   begin
      Stores.Find_Active_Password (Repository.Inner.all, Principal, Found, Credential);
   end Find_Active_Password;

   overriding procedure Find_Principal
     (Repository : Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Found      : out Boolean;
      Value      : out Identity.Principals.Definitions.Principal_Record)
   is
   begin
      Stores.Find_Principal (Repository.Inner.all, Principal, Found, Value);
   end Find_Principal;

   overriding procedure Find_Account
     (Repository : Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Found      : out Boolean;
      Account    : out Identity.Accounts.Definitions.Account_Record)
   is
   begin
      Stores.Find_Account (Repository.Inner.all, Principal, Found, Account);
   end Find_Account;

   overriding function Lookup_Session
     (Repository       : Store;
      Public_Reference : Identity.Text.Bounded.Bounded_Text;
      Secret           : Identity.Secrets.Sessions.Session_Secret;
      Now              : Identity.Times.Instant)
      return Identity.Sessions.Handles.Session_Handle
   is
   begin
      return Stores.Lookup_Session (Repository.Inner.all, Public_Reference, Secret, Now);
   end Lookup_Session;

   overriding function Renew_Session
     (Repository       : in out Store;
      Public_Reference : Identity.Text.Bounded.Bounded_Text;
      Secret           : Identity.Secrets.Sessions.Session_Secret;
      Now              : Identity.Times.Instant;
      Idle_Expires_At  : Identity.Times.Expiration)
      return Identity.Sessions.Handles.Session_Handle
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Renew_Session (Repository.Inner.all, Public_Reference, Secret, Now, Idle_Expires_At);
   end Renew_Session;

   overriding function Verify_Token
     (Repository : Store;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Purpose    : Identity.Identifiers.Registry.Registry_Id;
      Secret     : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now        : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
   begin
      return Stores.Verify_Token (Repository.Inner.all, Token, Purpose, Secret, Now);
   end Verify_Token;

   overriding function Consume_Token
     (Repository : in out Store;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Purpose    : Identity.Identifiers.Registry.Registry_Id;
      Secret     : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now        : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Consume_Token (Repository.Inner.all, Token, Purpose, Secret, Now);
   end Consume_Token;

   overriding function Consume_Token
     (Repository       : in out Store;
      Token            : Identity.Identifiers.Entities.Token_Id;
      Expected_Version : Identity.Versions.Entity_Version;
      Purpose          : Identity.Identifiers.Registry.Registry_Id;
      Secret           : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now              : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Consume_Token (Repository.Inner.all, Token, Expected_Version, Purpose, Secret, Now);
   end Consume_Token;

   overriding function Complete_Password_Reset
     (Repository : in out Store;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Purpose    : Identity.Identifiers.Registry.Registry_Id;
      Secret     : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now        : Identity.Times.Instant;
      Successor  : Identity.Passwords.Credentials.Password_Credential_Record)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Complete_Password_Reset (Repository.Inner.all, Token, Purpose, Secret, Now, Successor);
   end Complete_Password_Reset;

   overriding function Complete_Password_Reset
     (Repository                   : in out Store;
      Token                        : Identity.Identifiers.Entities.Token_Id;
      Expected_Token_Version       : Identity.Versions.Entity_Version;
      Expected_Predecessor_Version : Identity.Versions.Entity_Version;
      Purpose                      : Identity.Identifiers.Registry.Registry_Id;
      Secret                       : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now                          : Identity.Times.Instant;
      Successor                    : Identity.Passwords.Credentials.Password_Credential_Record)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Complete_Password_Reset
        (Repository.Inner.all,
         Token,
         Expected_Token_Version,
         Expected_Predecessor_Version,
         Purpose,
         Secret,
         Now,
         Successor);
   end Complete_Password_Reset;

   overriding function Authenticate_API_Key
     (Repository    : in out Store;
      Public_Key_Id : Identity.Text.Bounded.Bounded_Text;
      Secret        : Identity.Secrets.API_Keys.API_Key_Secret;
      Now           : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Authenticate_API_Key (Repository.Inner.all, Public_Key_Id, Secret, Now);
   end Authenticate_API_Key;

   overriding function Authenticate_API_Key
     (Repository                  : in out Store;
      Public_Key_Id               : Identity.Text.Bounded.Bounded_Text;
      Secret                      : Identity.Secrets.API_Keys.API_Key_Secret;
      Now                         : Identity.Times.Instant;
      Expected_Credential_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Results.Password_Authentication_Result
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Authenticate_API_Key
        (Repository.Inner.all,
         Public_Key_Id,
         Secret,
         Now,
         Expected_Credential_Version);
   end Authenticate_API_Key;

   overriding function Failure_Count
     (Repository : Store;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Category   : Identity.Attempts.Outcomes.Failure_Category)
      return Identity.Versions.Attempt_Count
   is
   begin
      return Stores.Failure_Count (Repository.Inner.all, Principal, Category);
   end Failure_Count;

   overriding function Consume_Recovery_Code
     (Repository : in out Store;
      Set_Id     : Identity.Identifiers.Entities.Credential_Set_Id;
      Code       : Identity.Secrets.Recovery_Codes.Recovery_Code)
      return Identity.Recovery_Codes.Sets.Recovery_Code_Consume_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Consume_Recovery_Code (Repository.Inner.all, Set_Id, Code);
   end Consume_Recovery_Code;

   overriding function Consume_Recovery_Code
     (Repository       : in out Store;
      Set_Id           : Identity.Identifiers.Entities.Credential_Set_Id;
      Expected_Version : Identity.Versions.Entity_Version;
      Code             : Identity.Secrets.Recovery_Codes.Recovery_Code)
      return Identity.Recovery_Codes.Sets.Recovery_Code_Consume_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Consume_Recovery_Code (Repository.Inner.all, Set_Id, Expected_Version, Code);
   end Consume_Recovery_Code;

   overriding function Authenticate_External
     (Repository : in out Store;
      Assertion  : Identity.External_Providers.Assertions.Normalized_Assertion;
      Now        : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Authenticate_External (Repository.Inner.all, Assertion, Now);
   end Authenticate_External;

   overriding function Authenticate_External
     (Repository               : in out Store;
      Assertion                : Identity.External_Providers.Assertions.Normalized_Assertion;
      Now                      : Identity.Times.Instant;
      Expected_Binding_Version : Identity.Versions.Entity_Version)
      return Identity.Authentication.Results.Password_Authentication_Result
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Authenticate_External (Repository.Inner.all, Assertion, Now, Expected_Binding_Version);
   end Authenticate_External;

   overriding function Accept_TOTP_Counter
     (Repository : in out Store;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Counter    : Identity.One_Time_Passwords.Credentials.TOTP_Counter)
      return Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Accept_TOTP_Counter (Repository.Inner.all, Credential, Counter);
   end Accept_TOTP_Counter;

   overriding function Accept_TOTP_Counter
     (Repository       : in out Store;
      Credential       : Identity.Identifiers.Entities.Credential_Id;
      Expected_Version : Identity.Versions.Entity_Version;
      Counter          : Identity.One_Time_Passwords.Credentials.TOTP_Counter)
      return Identity.One_Time_Passwords.Credentials.TOTP_Accept_Status
   is
   begin
      Repository.Calls := Repository.Calls + 1;
      Repository.Total := Repository.Total + 1;
      return Stores.Accept_TOTP_Counter (Repository.Inner.all, Credential, Expected_Version, Counter);
   end Accept_TOTP_Counter;

   overriding function Principal_Count (Repository : Store) return Natural
   is
   begin
      return Stores.Principal_Count (Repository.Inner.all);
   end Principal_Count;

   overriding function Account_Count (Repository : Store) return Natural
   is
   begin
      return Stores.Account_Count (Repository.Inner.all);
   end Account_Count;

   overriding function Binding_Count (Repository : Store) return Natural
   is
   begin
      return Stores.Binding_Count (Repository.Inner.all);
   end Binding_Count;

   overriding function Password_Credential_Count (Repository : Store) return Natural
   is
   begin
      return Stores.Password_Credential_Count (Repository.Inner.all);
   end Password_Credential_Count;

   overriding function Session_Count (Repository : Store) return Natural
   is
   begin
      return Stores.Session_Count (Repository.Inner.all);
   end Session_Count;

   overriding function Token_Count (Repository : Store) return Natural
   is
   begin
      return Stores.Token_Count (Repository.Inner.all);
   end Token_Count;

   overriding function Authentication_Transaction_Count (Repository : Store) return Natural
   is
   begin
      return Stores.Authentication_Transaction_Count (Repository.Inner.all);
   end Authentication_Transaction_Count;

   overriding function Challenge_Count (Repository : Store) return Natural
   is
   begin
      return Stores.Challenge_Count (Repository.Inner.all);
   end Challenge_Count;

   overriding function API_Key_Count (Repository : Store) return Natural
   is
   begin
      return Stores.API_Key_Count (Repository.Inner.all);
   end API_Key_Count;

   overriding procedure Find_Event
     (Repository : Store;
      Position   : Positive;
      Found      : out Boolean;
      Value      : out Identity.Events.Envelopes.Event_Envelope)
   is
   begin
      Stores.Find_Event (Repository.Inner.all, Position, Found, Value);
   end Find_Event;

   overriding function Event_Count (Repository : Store) return Natural
   is
   begin
      return Stores.Event_Count (Repository.Inner.all);
   end Event_Count;

   overriding function Attempt_Count (Repository : Store) return Natural
   is
   begin
      return Stores.Attempt_Count (Repository.Inner.all);
   end Attempt_Count;

   overriding function Contact_Binding_Count (Repository : Store) return Natural
   is
   begin
      return Stores.Contact_Binding_Count (Repository.Inner.all);
   end Contact_Binding_Count;

   overriding function Contact_Change_Count (Repository : Store) return Natural
   is
   begin
      return Stores.Contact_Change_Count (Repository.Inner.all);
   end Contact_Change_Count;

   overriding function Recovery_Code_Set_Count (Repository : Store) return Natural
   is
   begin
      return Stores.Recovery_Code_Set_Count (Repository.Inner.all);
   end Recovery_Code_Set_Count;

   overriding function Recovery_Transaction_Count (Repository : Store) return Natural
   is
   begin
      return Stores.Recovery_Transaction_Count (Repository.Inner.all);
   end Recovery_Transaction_Count;

   overriding function External_Binding_Count (Repository : Store) return Natural
   is
   begin
      return Stores.External_Binding_Count (Repository.Inner.all);
   end External_Binding_Count;

   overriding function External_Replay_Count (Repository : Store) return Natural
   is
   begin
      return Stores.External_Replay_Count (Repository.Inner.all);
   end External_Replay_Count;

   overriding function TOTP_Credential_Count (Repository : Store) return Natural
   is
   begin
      return Stores.TOTP_Credential_Count (Repository.Inner.all);
   end TOTP_Credential_Count;

end Identity.Adapters.Repositories.Recording;
