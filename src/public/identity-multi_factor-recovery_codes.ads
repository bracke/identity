with Identity.Authentication.Evidence;

package Identity.Multi_Factor.Recovery_Codes is
   pragma Pure;

   function Evidence_Category return Identity.Authentication.Evidence.Factor_Category is
     (Identity.Authentication.Evidence.Recovery);
end Identity.Multi_Factor.Recovery_Codes;
