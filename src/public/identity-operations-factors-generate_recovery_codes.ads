with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Recovery_Codes.Sets;
with Identity.Secrets.Recovery_Codes;
with Identity.Text.Bounded;
with Identity.Times;

package Identity.Operations.Factors.Generate_Recovery_Codes is
   subtype Recovery_Code_Count is Natural range 0 .. Identity.Recovery_Codes.Sets.Max_Codes_Per_Set;

   type Recovery_Code_Input is record
      Code_Id : Identity.Text.Bounded.Bounded_Text;
      Secret  : Identity.Secrets.Recovery_Codes.Recovery_Code;
   end record;

   type Recovery_Code_Input_List is
     array (Positive range 1 .. Identity.Recovery_Codes.Sets.Max_Codes_Per_Set)
       of Recovery_Code_Input;

   type Generate_Request is record
      Id         : Identity.Identifiers.Entities.Credential_Set_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Created_At : Identity.Times.Instant := 0;
      Count      : Recovery_Code_Count := 0;
      Codes      : Recovery_Code_Input_List;
   end record;

   function To_Record (Request : Generate_Request)
      return Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record;

   --  Audited form. Emits identity.recovery-codes.generated for the install,
   --  and refuses the operation if the store cannot accept that event, so a
   --  fresh set of account-recovery secrets never appears unrecorded.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Generate_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form of the shape above. Same event, same subject and
   --  target, same refusal rule as the audited request form.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Codes       : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Factors.Generate_Recovery_Codes;
