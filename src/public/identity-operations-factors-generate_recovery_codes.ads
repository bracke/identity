with Identity.Adapters.Repositories.Memory;
with Identity.Identifiers.Entities;
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

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Codes      : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Generate_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status;
end Identity.Operations.Factors.Generate_Recovery_Codes;
