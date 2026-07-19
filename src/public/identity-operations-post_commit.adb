package body Identity.Operations.Post_Commit is
   use type Identity.Sessions.Handles.Session_Lookup_Status;

   function Count_Matches (Output : Post_Commit_Output) return Boolean is
   begin
      for Index in Output.Events.References'Range loop
         if (Index <= Output.Events.Count) /= Output.Events.References (Index).Present then
            return False;
         end if;
      end loop;

      for Index in Output.Publications.Publications'Range loop
         if (Index <= Output.Publications.Count) /= Output.Publications.Publications (Index).Present then
            return False;
         end if;
      end loop;

      for Index in Output.Notification_Handoff.Deliveries'Range loop
         if (Index <= Output.Notification_Handoff.Count)
           /= Output.Notification_Handoff.Deliveries (Index).Present
         then
            return False;
         end if;
      end loop;

      for Index in Output.One_Time_Outputs.Outputs'Range loop
         if (Index <= Output.One_Time_Outputs.Count) /= Output.One_Time_Outputs.Outputs (Index).Present then
            return False;
         end if;
      end loop;

      return True;
   end Count_Matches;

   function Events_Are_Post_Commit (Output : Post_Commit_Output) return Boolean is
   begin
      for Index in 1 .. Output.Publications.Count loop
         if not Identity.Adapters.Event_Sinks.Publishable
           (Output.Publications.Publications (Index).Value)
         then
            return False;
         end if;
      end loop;

      return True;
   end Events_Are_Post_Commit;

   function Notifications_Are_Safe (Output : Post_Commit_Output) return Boolean is
   begin
      for Index in 1 .. Output.Notification_Handoff.Count loop
         if not Identity.Adapters.Notifications.Safe_For_Adapter
           (Output.Notification_Handoff.Deliveries (Index).Value)
         then
            return False;
         end if;
      end loop;

      return True;
   end Notifications_Are_Safe;

   function One_Time_Outputs_Are_Returnable (Output : Post_Commit_Output) return Boolean is
   begin
      for Index in 1 .. Output.One_Time_Outputs.Count loop
         if not Identity.Tokens.Generation.Safe_To_Return
           (Output.One_Time_Outputs.Outputs (Index).Value)
         then
            return False;
         end if;
      end loop;

      return True;
   end One_Time_Outputs_Are_Returnable;

   function Has_Post_Commit_Work (Output : Post_Commit_Output) return Boolean is
   begin
      return Output.Events.Count > 0
        or else Output.Publications.Count > 0
        or else Output.Notification_Handoff.Count > 0
        or else Output.One_Time_Outputs.Count > 0
        or else Output.Session_Issuance.Status = Identity.Sessions.Handles.Found;
   end Has_Post_Commit_Work;

   function Admit_For_Release (Output : Post_Commit_Output) return Release_Admission is
   begin
      if not Count_Matches (Output) then
         return (Ready => False, Reason => Count_Mismatch);
      elsif not Events_Are_Post_Commit (Output) then
         return (Ready => False, Reason => Publication_Not_Post_Commit);
      elsif not Notifications_Are_Safe (Output) then
         return (Ready => False, Reason => Unsafe_Notification);
      elsif not One_Time_Outputs_Are_Returnable (Output) then
         return (Ready => False, Reason => Unsafe_One_Time_Output);
      else
         return (Ready => True, Reason => None);
      end if;
   end Admit_For_Release;

   function Ready_For_Release (Output : Post_Commit_Output) return Boolean is
     (Admit_For_Release (Output).Ready);
end Identity.Operations.Post_Commit;
