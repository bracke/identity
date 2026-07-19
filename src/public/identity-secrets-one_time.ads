with Identity.Secrets.Bytes;

package Identity.Secrets.One_Time is
   type One_Time_Secret is private;
   function Create (Value : Identity.Secrets.Bytes.Secret_Bytes) return One_Time_Secret;
   function Is_Consumed (Value : One_Time_Secret) return Boolean;
   procedure Extract (Value : in out One_Time_Secret; Secret : out Identity.Secrets.Bytes.Secret_Bytes)
     with Pre => not Is_Consumed (Value);
private
   type One_Time_Secret is record
      Consumed : Boolean := False;
      Secret   : Identity.Secrets.Bytes.Secret_Bytes;
   end record;
end Identity.Secrets.One_Time;
