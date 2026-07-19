with Identity.Authentication.Evidence;

package Identity.Multi_Factor.One_Time_Passwords is
   pragma Pure;

   function Evidence_Category return Identity.Authentication.Evidence.Factor_Category is
     (Identity.Authentication.Evidence.Possession);
end Identity.Multi_Factor.One_Time_Passwords;
