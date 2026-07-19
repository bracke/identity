with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Times;

package Identity.Authentication.Evidence is
   pragma Pure;
   use type Identity.Identifiers.Entities.Authentication_Transaction_Id;
   use type Identity.Identifiers.Entities.Challenge_Id;
   use type Identity.Identifiers.Entities.Principal_Id;

   type Factor_Category is
     (Knowledge, Possession, Inherence, External_Federation, Recovery, System_Attestation);

   type Evidence_Record is record
      Id              : Identity.Identifiers.Entities.Evidence_Id;
      Principal       : Identity.Identifiers.Entities.Principal_Id;
      Transaction     : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Challenge_Present : Boolean := False;
      Challenge       : Identity.Identifiers.Entities.Challenge_Id;
      Method          : Identity.Identifiers.Registry.Registry_Id;
      Category        : Factor_Category := Knowledge;
      Verified_At     : Identity.Times.Instant := 0;
      Schema_Version  : Positive := 1;
      Recovery_Used   : Boolean := False;
   end record;

   function Bound_To_Principal
     (Evidence  : Evidence_Record;
      Principal : Identity.Identifiers.Entities.Principal_Id) return Boolean is
     (Evidence.Principal = Principal);

   function Bound_To_Transaction
     (Evidence    : Evidence_Record;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id)
      return Boolean is
     (Evidence.Transaction = Transaction);

   function Bound_To_Challenge
     (Evidence  : Evidence_Record;
      Challenge : Identity.Identifiers.Entities.Challenge_Id) return Boolean is
     (Evidence.Challenge_Present and then Evidence.Challenge = Challenge);

   function Transferable_To
     (Evidence    : Evidence_Record;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id)
      return Boolean is
     (Bound_To_Principal (Evidence, Principal)
      and then Bound_To_Transaction (Evidence, Transaction));
end Identity.Authentication.Evidence;
