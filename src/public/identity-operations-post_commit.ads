with Identity.Adapters.Event_Sinks;
with Identity.Adapters.Notifications;
with Identity.Identifiers.Entities;
with Identity.Limits;
with Identity.Sessions.Handles;
with Identity.Tokens.Generation;

package Identity.Operations.Post_Commit is
   Max_Event_References : constant Natural := Identity.Limits.Max_Events_Per_Operation;
   Max_Publications     : constant Natural := Identity.Limits.Max_Events_Per_Operation;
   Max_Deliveries       : constant Natural := Identity.Limits.Max_Events_Per_Operation;
   Max_One_Time_Outputs : constant Natural := Identity.Limits.Max_Events_Per_Operation;

   type Optional_Event_Id (Present : Boolean := False) is record
      case Present is
         when True =>
            Value : Identity.Identifiers.Entities.Event_Id;
         when False =>
            null;
      end case;
   end record;

   type Event_Reference_List is array (Positive range 1 .. Max_Event_References) of Optional_Event_Id;

   type Event_Reference_Batch is record
      Count      : Natural range 0 .. Max_Event_References := 0;
      References : Event_Reference_List := [others => (Present => False)];
   end record;

   type Optional_Publication (Present : Boolean := False) is record
      case Present is
         when True =>
            Value : Identity.Adapters.Event_Sinks.Event_Publication;
         when False =>
            null;
      end case;
   end record;

   type Publication_List is array (Positive range 1 .. Max_Publications) of Optional_Publication;

   type Publication_Batch is record
      Count        : Natural range 0 .. Max_Publications := 0;
      Publications : Publication_List := [others => (Present => False)];
   end record;

   type Optional_Delivery (Present : Boolean := False) is record
      case Present is
         when True =>
            Value : Identity.Adapters.Notifications.Delivery_Request;
         when False =>
            null;
      end case;
   end record;

   type Delivery_List is array (Positive range 1 .. Max_Deliveries) of Optional_Delivery;

   type Delivery_Batch is record
      Count      : Natural range 0 .. Max_Deliveries := 0;
      Deliveries : Delivery_List := [others => (Present => False)];
   end record;

   type Optional_One_Time_Output (Present : Boolean := False) is record
      case Present is
         when True =>
            Value : Identity.Tokens.Generation.Split_Token;
         when False =>
            null;
      end case;
   end record;

   type One_Time_Output_List is array (Positive range 1 .. Max_One_Time_Outputs) of Optional_One_Time_Output;

   type One_Time_Output_Batch is record
      Count   : Natural range 0 .. Max_One_Time_Outputs := 0;
      Outputs : One_Time_Output_List := [others => (Present => False)];
   end record;

   type Post_Commit_Output is record
      Events             : Event_Reference_Batch;
      Publications       : Publication_Batch;
      Notification_Handoff : Delivery_Batch;
      One_Time_Outputs   : One_Time_Output_Batch;
      Session_Issuance   : Identity.Sessions.Handles.Session_Handle :=
        (Status => Identity.Sessions.Handles.Unknown);
   end record;

   type Release_Rejection is
     (None,
      Count_Mismatch,
      Publication_Not_Post_Commit,
      Unsafe_Notification,
      Unsafe_One_Time_Output);

   type Release_Admission is record
      Ready  : Boolean := False;
      Reason : Release_Rejection := None;
   end record;

   function Count_Matches (Output : Post_Commit_Output) return Boolean;
   function Events_Are_Post_Commit (Output : Post_Commit_Output) return Boolean;
   function Notifications_Are_Safe (Output : Post_Commit_Output) return Boolean;
   function One_Time_Outputs_Are_Returnable (Output : Post_Commit_Output) return Boolean;
   function Has_Post_Commit_Work (Output : Post_Commit_Output) return Boolean;
   function Admit_For_Release (Output : Post_Commit_Output) return Release_Admission;
   function Ready_For_Release (Output : Post_Commit_Output) return Boolean;

   function Accepted (Admission : Release_Admission) return Boolean is
     (Admission.Ready and then Admission.Reason = None);

   function Rejected (Admission : Release_Admission) return Boolean is
     (not Admission.Ready);

   function Count_Mismatch_Rejection (Reason : Release_Rejection) return Boolean is
     (Reason = Count_Mismatch);

   function Publication_Timing_Rejection (Reason : Release_Rejection) return Boolean is
     (Reason = Publication_Not_Post_Commit);

   function Notification_Rejection (Reason : Release_Rejection) return Boolean is
     (Reason = Unsafe_Notification);

   function One_Time_Output_Rejection (Reason : Release_Rejection) return Boolean is
     (Reason = Unsafe_One_Time_Output);

   function Safety_Rejection (Reason : Release_Rejection) return Boolean is
     (Reason in Publication_Not_Post_Commit | Unsafe_Notification | Unsafe_One_Time_Output);
end Identity.Operations.Post_Commit;
