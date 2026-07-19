with Identity.Authentication.Challenges;

package Identity.Multi_Factor.Challenges is
   pragma Pure;

   subtype Challenge_Record is Identity.Authentication.Challenges.Challenge_Record;
   subtype Challenge_State is Identity.Authentication.Challenges.Challenge_State;
end Identity.Multi_Factor.Challenges;
