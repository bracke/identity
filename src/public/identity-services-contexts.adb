with Identity.Policies.Findings;
with Identity.Policies.Validation;

package body Identity.Services.Contexts is
   function Is_Usable (Context : Service_Context) return Boolean is
     (Identity.Services.Capabilities.Production_Ready (Context.Capabilities)
      and then not Identity.Policies.Findings.Has_Errors
        (Identity.Policies.Validation.Validate (Context.Policy)));
end Identity.Services.Contexts;
