with Identity.Adapters.Repositories.Conflicts;

package Identity.Adapters.Repositories.Commands is
   pragma Pure;
   use type Identity.Adapters.Repositories.Conflicts.Conflict_Category;

   type Command_Outcome is
     (Applied, Rejected, Conflict, Capacity_Exceeded, Infrastructure_Failure);

   type Command_Result is record
      Outcome  : Command_Outcome := Rejected;
      Conflict : Identity.Adapters.Repositories.Conflicts.Conflict_Category :=
        Identity.Adapters.Repositories.Conflicts.State_Conflict;
   end record;

   function Success return Command_Result is
     ((Outcome => Applied,
       Conflict => Identity.Adapters.Repositories.Conflicts.State_Conflict));

   function Rejection return Command_Result is
     ((Outcome => Rejected,
       Conflict => Identity.Adapters.Repositories.Conflicts.State_Conflict));

   function Conflict_Result
     (Category : Identity.Adapters.Repositories.Conflicts.Conflict_Category)
      return Command_Result is
     ((Outcome => Conflict, Conflict => Category));

   function Is_Applied (Result : Command_Result) return Boolean is
     (Result.Outcome = Applied);

   function Is_Rejected (Result : Command_Result) return Boolean is
     (Result.Outcome = Rejected);

   function Is_Conflict (Result : Command_Result) return Boolean is
     (Result.Outcome = Conflict);

   function Capacity_Rejected (Result : Command_Result) return Boolean is
     (Result.Outcome = Capacity_Exceeded);

   function Infrastructure_Failed (Result : Command_Result) return Boolean is
     (Result.Outcome = Infrastructure_Failure);

   function Operational_Failure (Result : Command_Result) return Boolean is
     (Result.Outcome in Capacity_Exceeded | Infrastructure_Failure);

   function No_Mutation (Result : Command_Result) return Boolean is
     (Result.Outcome in Rejected | Conflict | Capacity_Exceeded | Infrastructure_Failure);

   function Conflicts_As
     (Result   : Command_Result;
      Category : Identity.Adapters.Repositories.Conflicts.Conflict_Category)
      return Boolean is
     (Result.Outcome = Conflict and then Result.Conflict = Category);
end Identity.Adapters.Repositories.Commands;
