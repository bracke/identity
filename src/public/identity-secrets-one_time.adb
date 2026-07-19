package body Identity.Secrets.One_Time is
   function Create (Value : Identity.Secrets.Bytes.Secret_Bytes) return One_Time_Secret is
     ((Consumed => False, Secret => Value));

   function Is_Consumed (Value : One_Time_Secret) return Boolean is
     (Value.Consumed);

   procedure Extract (Value : in out One_Time_Secret; Secret : out Identity.Secrets.Bytes.Secret_Bytes) is
   begin
      Secret := Value.Secret;
      Identity.Secrets.Bytes.Clear (Value.Secret);
      Value.Consumed := True;
   end Extract;
end Identity.Secrets.One_Time;
