with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Times;
with Identity.Verification.Changes;
with Identity.Versions;

--  Advance a contact change through one of its mid-flow admission actions --
--  recording old-contact confirmation, starting the cooling-off period,
--  cancelling, or expiring. Before this, those states of the change machine
--  were unreachable: a change could only be begun and then completed. Audited
--  under identity.contact.change.advanced, so each gate a contact change passes
--  is reconstructable, not just the open and the close.
package Identity.Operations.Verification.Advance_Contact_Change is
   function Execute
     (Repository       : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Token            : Identity.Identifiers.Entities.Token_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Action           : Identity.Verification.Changes.Contact_Change_Action;
      Expected_Version : Identity.Versions.Entity_Version;
      Context          : Identity.Operations.Contexts.Operation_Context;
      Event            : Identity.Identifiers.Entities.Event_Id;
      Recorded_At      : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Verification.Advance_Contact_Change;
