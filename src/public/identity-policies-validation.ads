with Identity.Policies.Findings;
with Identity.Policies.Snapshots;

package Identity.Policies.Validation is
   pragma Pure;

   function Validate
     (Snapshot : Identity.Policies.Snapshots.Policy_Snapshot)
      return Identity.Policies.Findings.Finding_Report;
end Identity.Policies.Validation;
