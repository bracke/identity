with Identity.Errors;

package Identity.Adapters.Repositories.Failures is
   pragma Pure;

   type Repository_Failure_Code is
     (No_Failure,
      Context_Not_Open,
      Transaction_Already_Active,
      Transaction_Not_Active,
      Already_Finalized,
      Capability_Lost,
      Backend_Unavailable,
      Commit_Failed,
      Rollback_Failed);

   type Repository_Failure is record
      Code  : Repository_Failure_Code := No_Failure;
      Error : Identity.Errors.Error_Value;
   end record;

   function Is_Failure (Failure : Repository_Failure) return Boolean is
     (Failure.Code /= No_Failure);
end Identity.Adapters.Repositories.Failures;
