with Identity.Adapters.Repositories.Stores;
with Identity.Assurance.Attributes;
with Identity.Assurance.Levels;
with Identity.Authentication.Transactions;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Multi_Factor.Step_Up;
with Identity.Operations.Contexts;
with Identity.Times;

package Identity.Operations.Authentication.Step_Up is

   --  Bound step-up. Unlike the plain form, this verifies the target session
   --  still matches the family and rotation generation the caller expects -- a
   --  rotated or replaced session no longer matches, so a stale step-up cannot
   --  raise the wrong session -- and short-circuits when the session already
   --  satisfies the requested profile, so a redundant re-upgrade is a no-op
   --  rather than a spurious assurance event. Only when a real raise is needed
   --  does it perform the audited atomic upgrade.
   function Execute
     (Repository        : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Binding           : Identity.Multi_Factor.Step_Up.Step_Up_Binding;
      Transaction       : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Requested_Profile : Identity.Identifiers.Registry.Registry_Id;
      Now               : Identity.Times.Instant;
      Assurance         : Identity.Assurance.Levels.Assurance_Level;
      Attributes        : Identity.Assurance.Attributes.Assurance_Attributes;
      Context           : Identity.Operations.Contexts.Operation_Context;
      Event             : Identity.Identifiers.Entities.Event_Id;
      Recorded_At       : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;

   --  Audited step-up: a session that gains assurance without a record leaves
   --  no answer to "what raised this session's standing, and when?".
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Session     : Identity.Identifiers.Entities.Session_Id;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Now         : Identity.Times.Instant;
      Assurance   : Identity.Assurance.Levels.Assurance_Level;
      Attributes  : Identity.Assurance.Attributes.Assurance_Attributes;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Authentication.Transactions.Authentication_Transaction_Status;
end Identity.Operations.Authentication.Step_Up;
