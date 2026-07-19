with Identity.Crypto.Domains;
with Identity.Crypto.Secret_Verifiers;

package body Identity.Operations.Factors.Generate_Recovery_Codes is
   function To_Record (Request : Generate_Request)
      return Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record
   is
      Result : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record :=
        (Id         => Request.Id,
         Principal  => Request.Principal,
         Created_At => Request.Created_At,
         Version    => 0,
         Count      => Request.Count,
         Codes      => [others =>
           (Code_Id => Identity.Text.Bounded.From_String (""),
            Secret_Verifier => Identity.Text.Bounded.From_String (""),
            State => Identity.Recovery_Codes.Sets.Revoked)]);
   begin
      for Index in 1 .. Request.Count loop
         Result.Codes (Index) :=
           (Code_Id => Request.Codes (Index).Code_Id,
            Secret_Verifier => Identity.Crypto.Secret_Verifiers.Derive_Text
              (Identity.Crypto.Domains.Recovery_Code, Request.Codes (Index).Secret),
            State => Identity.Recovery_Codes.Sets.Active);
      end loop;
      return Result;
   end To_Record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Codes      : Identity.Recovery_Codes.Sets.Recovery_Code_Set_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Install_Recovery_Code_Set (Repository, Codes);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Generate_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Install_Recovery_Code_Set
        (Repository, To_Record (Request));
   end Execute;
end Identity.Operations.Factors.Generate_Recovery_Codes;
