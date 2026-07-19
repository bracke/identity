with Identity.External_Providers.Bindings;
with Identity.External_Providers.Assertions;
with Identity.Identifiers.Entities;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

package Identity.Projections.External_Bindings is
   pragma Pure;

   type External_Binding_Projection is record
      Id               : Identity.Identifiers.Entities.External_Binding_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Provider         : Identity.Identifiers.Entities.External_Provider_Id;
      Issuer           : Identity.Text.Bounded.Bounded_Text;
      External_Subject : Identity.Text.Bounded.Bounded_Text;
      State            : Identity.External_Providers.Bindings.External_Binding_State;
      Created_At       : Identity.Times.Instant;
      Version          : Identity.Versions.Entity_Version;
   end record;

   function Summary
     (Binding : Identity.External_Providers.Bindings.External_Binding_Record)
      return External_Binding_Projection is
     ((Id               => Binding.Id,
       Principal        => Binding.Principal,
       Provider         => Binding.Provider,
       Issuer           => Binding.Issuer,
       External_Subject => Binding.External_Subject,
       State            => Binding.State,
       Created_At       => Binding.Created_At,
       Version          => Binding.Version));

   function Usable_For_Authentication
     (Projection : External_Binding_Projection) return Boolean is
     (Identity.External_Providers.Bindings.Usable_For_Authentication
        (Projection.State));

   function Same_External_Key
     (Left, Right : External_Binding_Projection) return Boolean is
     (Identity.Identifiers.Entities.To_String (Left.Provider)
      = Identity.Identifiers.Entities.To_String (Right.Provider)
      and then Identity.Text.Bounded.Equal (Left.Issuer, Right.Issuer)
      and then Identity.Text.Bounded.Equal
        (Left.External_Subject, Right.External_Subject));

   function Same_Active_External_Key
     (Left, Right : External_Binding_Projection) return Boolean is
     (Usable_For_Authentication (Left)
      and then Usable_For_Authentication (Right)
      and then Same_External_Key (Left, Right));

   function Matches_Assertion
     (Projection : External_Binding_Projection;
      Assertion  : Identity.External_Providers.Assertions.Normalized_Assertion)
      return Boolean is
     (Identity.Identifiers.Entities.To_String (Projection.Provider)
      = Identity.Identifiers.Entities.To_String (Assertion.Provider)
      and then Identity.Text.Bounded.Equal (Projection.Issuer, Assertion.Issuer)
      and then Identity.Text.Bounded.Equal
        (Projection.External_Subject, Assertion.External_Subject));

   function Active_Matches_Assertion
     (Projection : External_Binding_Projection;
      Assertion  : Identity.External_Providers.Assertions.Normalized_Assertion)
      return Boolean is
     (Usable_For_Authentication (Projection)
      and then Matches_Assertion (Projection, Assertion));
end Identity.Projections.External_Bindings;
