with Identity.Identifiers.Registry;
with Identity.Text.Messages;

package Identity.Errors.Messages is
   function Message_For
     (Category : Identity.Errors.Error_Category) return Identity.Identifiers.Registry.Registry_Id is
     (case Category is
        when Identity.Errors.Success =>
           Identity.Text.Messages.Operational_Failure,
        when Identity.Errors.Rejection | Identity.Errors.Additional_Action_Required =>
           Identity.Text.Messages.Authentication_Rejected,
        when Identity.Errors.Conflict =>
           Identity.Text.Messages.Operation_Conflict,
        when others =>
           Identity.Text.Messages.Operational_Failure);
end Identity.Errors.Messages;
