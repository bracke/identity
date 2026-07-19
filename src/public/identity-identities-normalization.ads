with Identity.Identities.Subjects;

package Identity.Identities.Normalization is
   pragma Pure;

   function Already_Normalized
     (Subject : Identity.Identities.Subjects.Authentication_Subject)
      return Identity.Identities.Subjects.Authentication_Subject is (Subject);
end Identity.Identities.Normalization;
