package Identity.Limits is
   pragma Pure;

   Max_Public_Text_Bytes       : constant Natural := 512;
   Max_Secret_Bytes            : constant Natural := 4096;
   Max_Password_Bytes          : constant Natural := 1024;
   Max_Bearer_Secret_Bytes     : constant Natural := 128;
   Max_Recovery_Code_Bytes     : constant Natural := 64;
   Max_Registry_Id_Bytes       : constant Natural := 96;
   Max_Event_Attributes        : constant Natural := 32;
   Max_Evidence_Per_Context    : constant Natural := 16;
   Max_Methods_Per_Context     : constant Natural := 16;
   Max_Password_History_Checks : constant Natural := 24;
   Max_Repository_Reads        : constant Natural := 1_024;
   Max_Repository_Writes       : constant Natural := 1_024;
   Max_Entities_Loaded         : constant Natural := 256;
   Max_Cryptographic_Operations : constant Natural := 256;
   Max_Factor_Challenges       : constant Natural := 32;
   Max_Events_Per_Operation    : constant Natural := 64;
   Max_Collection_Capacity     : constant Natural := 512;
   Max_Operation_Retries       : constant Natural := 8;
   Max_Input_Bytes             : constant Natural := 8_192;
   Max_Output_Bytes            : constant Natural := 8_192;
   Max_TOTP_Skew_Steps         : constant Natural := 2;
   Max_Session_Retention_Days  : constant Natural := 366;
end Identity.Limits;
