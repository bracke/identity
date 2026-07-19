with Identity.External_Providers.Assertions;
with Identity.External_Providers.Bindings;
with Identity.Projections.External_Bindings;

package Identity.External_Providers.Projections is
   pragma Pure;

   subtype External_Binding_Projection is
     Identity.Projections.External_Bindings.External_Binding_Projection;

   function Summary
     (Binding : Identity.External_Providers.Bindings.External_Binding_Record)
      return External_Binding_Projection
      renames Identity.Projections.External_Bindings.Summary;

   function Usable_For_Authentication
     (Projection : External_Binding_Projection) return Boolean
      renames Identity.Projections.External_Bindings.Usable_For_Authentication;

   function Same_External_Key
     (Left, Right : External_Binding_Projection) return Boolean
      renames Identity.Projections.External_Bindings.Same_External_Key;

   function Same_Active_External_Key
     (Left, Right : External_Binding_Projection) return Boolean
      renames Identity.Projections.External_Bindings.Same_Active_External_Key;

   function Matches_Assertion
     (Projection : External_Binding_Projection;
      Assertion  : Identity.External_Providers.Assertions.Normalized_Assertion)
      return Boolean
      renames Identity.Projections.External_Bindings.Matches_Assertion;

   function Active_Matches_Assertion
     (Projection : External_Binding_Projection;
      Assertion  : Identity.External_Providers.Assertions.Normalized_Assertion)
      return Boolean
      renames Identity.Projections.External_Bindings.Active_Matches_Assertion;
end Identity.External_Providers.Projections;
