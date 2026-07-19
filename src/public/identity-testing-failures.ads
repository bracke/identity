package Identity.Testing.Failures is
   Max_Scripted_Failures : constant Natural := 32;
   subtype Failure_Count is Natural range 0 .. Max_Scripted_Failures;

   type Failure_Checkpoint is
     (Context_Open,
      Begin_Transaction,
      Read,
      After_Crypto_Snapshot,
      Before_Command_Apply,
      After_Command_Staging,
      Before_Event_Append,
      After_Event_Append,
      Before_Commit,
      Commit,
      Rollback,
      Post_Commit_Sink,
      Notification_Handoff,
      Entropy,
      Key_Lookup,
      Crypto_Service,
      Clock);

   type Failure_Script is record
      Checkpoint : Failure_Checkpoint := Context_Open;
      Armed      : Boolean := False;
      Remaining  : Failure_Count := 1;
      Consumed   : Failure_Count := 0;
   end record;

   function Valid (Script : Failure_Script) return Boolean is
     ((not Script.Armed or else Script.Remaining > 0)
      and then Script.Consumed <= Script.Remaining);

   function Should_Fail
     (Script : Failure_Script;
      Point  : Failure_Checkpoint) return Boolean is
     (Valid (Script)
      and then Script.Armed
      and then Script.Checkpoint = Point
      and then Script.Consumed < Script.Remaining);

   function Exhausted (Script : Failure_Script) return Boolean is
     (Valid (Script) and then Script.Consumed >= Script.Remaining);

   procedure Consume
     (Script    : in out Failure_Script;
      Point     : Failure_Checkpoint;
      Triggered : out Boolean);
end Identity.Testing.Failures;
