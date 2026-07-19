with Identity.Accounts.States;

package Identity.Accounts.Evaluation is
   pragma Pure;

   subtype Account_State_View is Identity.Accounts.States.Account_State_View;
   subtype Eligibility is Identity.Accounts.States.Eligibility;

   function Evaluate (State : Account_State_View) return Eligibility is
     (Identity.Accounts.States.Evaluate (State));
end Identity.Accounts.Evaluation;
