with Identity.Authentication.Evidence;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Times;

package Identity.Recovery.Evidence is
   pragma Pure;
   use type Identity.Authentication.Evidence.Factor_Category;

   type Recovery_Evidence_Source is
     (Recovery_Code,
      Verified_Recovery_Contact,
      External_Provider,
      Enrolled_Possession_Factor,
      Administrative_Approval,
      External_Proofing_Adapter);

   type Recovery_Evidence_Record is record
      Principal       : Identity.Identifiers.Entities.Principal_Id;
      Transaction     : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Evidence        : Identity.Authentication.Evidence.Evidence_Record;
      Source          : Recovery_Evidence_Source := Recovery_Code;
      Provider_Method : Identity.Identifiers.Registry.Registry_Id;
      Accepted_At     : Identity.Times.Instant := 0;
      Reduced_Assurance : Boolean := True;
   end record;

   type Recovery_Evidence_Projection is record
      Principal       : Identity.Identifiers.Entities.Principal_Id;
      Transaction     : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Evidence_Id     : Identity.Identifiers.Entities.Evidence_Id;
      Source          : Recovery_Evidence_Source := Recovery_Code;
      Provider_Method : Identity.Identifiers.Registry.Registry_Id;
      Accepted_At     : Identity.Times.Instant := 0;
      Reduced_Assurance : Boolean := True;
      Bound_To_Recovery_Transaction : Boolean := False;
   end record;

   function Bound_To_Recovery_Transaction
     (Value : Recovery_Evidence_Record) return Boolean is
     (Identity.Authentication.Evidence.Bound_To_Principal
        (Value.Evidence, Value.Principal)
      and then Identity.Authentication.Evidence.Bound_To_Transaction
        (Value.Evidence, Value.Transaction));

   function Is_Recovery_Category
     (Value : Recovery_Evidence_Record) return Boolean is
     (Value.Evidence.Category = Identity.Authentication.Evidence.Recovery
      or else Value.Evidence.Recovery_Used);

   function Restricted_Assurance
     (Value : Recovery_Evidence_Record) return Boolean is
     (Value.Reduced_Assurance or else Value.Evidence.Recovery_Used);

   function Summary
     (Value : Recovery_Evidence_Record) return Recovery_Evidence_Projection is
     ((Principal       => Value.Principal,
       Transaction     => Value.Transaction,
       Evidence_Id     => Value.Evidence.Id,
       Source          => Value.Source,
       Provider_Method => Value.Provider_Method,
       Accepted_At     => Value.Accepted_At,
       Reduced_Assurance => Restricted_Assurance (Value),
       Bound_To_Recovery_Transaction =>
         Bound_To_Recovery_Transaction (Value)));
end Identity.Recovery.Evidence;
