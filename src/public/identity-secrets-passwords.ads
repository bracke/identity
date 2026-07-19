with Identity.Secrets.Text;

package Identity.Secrets.Passwords is
   subtype Presented_Password is Identity.Secrets.Text.Secret_Text;
   subtype New_Password is Identity.Secrets.Text.Secret_Text;
end Identity.Secrets.Passwords;
