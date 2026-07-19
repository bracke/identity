with Identity.Identifiers.Operations;

package Identity.Correlation is
   pragma Pure;

   type Optional_Causation (Present : Boolean := False) is record
      case Present is
         when True =>
            Value : Identity.Identifiers.Operations.Causation_Id;
         when False =>
            null;
      end case;
   end record;

   type Correlation_Link is record
      Operation   : Identity.Identifiers.Operations.Operation_Id;
      Correlation : Identity.Identifiers.Operations.Correlation_Id;
      Causation   : Optional_Causation;
   end record;

   function Has_Causation (Value : Correlation_Link) return Boolean is
     (Value.Causation.Present);
end Identity.Correlation;
