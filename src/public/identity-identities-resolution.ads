with Identity.Identifiers.Entities;

package Identity.Identities.Resolution is
   pragma Pure;

   type Resolution_Status is (Resolved, Not_Found, Ambiguous, Unsupported, Operational_Failure);

   type Resolution_Result (Status : Resolution_Status := Not_Found) is record
      case Status is
         when Resolved =>
            Principal : Identity.Identifiers.Entities.Principal_Id;
         when Not_Found | Ambiguous | Unsupported | Operational_Failure =>
            null;
      end case;
   end record;

   function Successful (Status : Resolution_Status) return Boolean is
     (Status = Resolved);

   function Generic_Miss (Status : Resolution_Status) return Boolean is
     (Status = Not_Found);

   function Ambiguity_Detected (Status : Resolution_Status) return Boolean is
     (Status = Ambiguous);

   function Unsupported_Subject
     (Status : Resolution_Status) return Boolean is
     (Status = Unsupported);

   function Operational (Status : Resolution_Status) return Boolean is
     (Status = Operational_Failure);

   function Disclosure_Collapsed_Rejection
     (Status : Resolution_Status) return Boolean is
     (Status in Not_Found | Ambiguous);
end Identity.Identities.Resolution;
