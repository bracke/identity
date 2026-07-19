with Identity.Secrets.Bytes;

package Identity.Secrets.One_Time_Passwords is
   subtype TOTP_Secret is Identity.Secrets.Bytes.Secret_Bytes;
end Identity.Secrets.One_Time_Passwords;
