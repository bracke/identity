with Identity.Identifiers.Entities;
with Identity.Identifiers.Operations;
with Identity.Identifiers.Registry;
with Identity.Limits;
with Identity.Times;

package body Identity.Events.Canonical is
   function Trim_Image (Value : String) return String is
      First : Positive := Value'First;
   begin
      while First <= Value'Last and then Value (First) = ' ' loop
         First := First + 1;
      end loop;

      if First > Value'Last then
         return "0";
      end if;

      return Value (First .. Value'Last);
   end Trim_Image;

   function Principal_Image
     (Value : Identity.Events.Envelopes.Optional_Principal) return String is
   begin
      if Value.Present then
         return Identity.Identifiers.Entities.To_String (Value.Value);
      end if;

      return "-";
   end Principal_Image;

   function Actor_Principal_Image
     (Value : Identity.Events.Envelopes.Event_Actor) return String is
   begin
      return Principal_Image (Value.Principal);
   end Actor_Principal_Image;

   function Prefix_Of (Value : String; Count : Natural) return String is
   begin
      if Count = 0 then
         return "";
      end if;

      return Value (Value'First .. Value'First + Count - 1);
   end Prefix_Of;

   function Encode
     (Event : Identity.Events.Envelopes.Event_Envelope)
      return Identity.Text.Bounded.Bounded_Text
   is
      Prefix : constant String :=
        "identity-event-v1;" &
        "eid=" & Identity.Identifiers.Entities.To_String (Event.Id) & ";" &
        "type=" & Identity.Identifiers.Registry.Image (Event.Type_Id) & ";" &
        "schema=" & Trim_Image (Positive'Image (Event.Schema)) & ";" &
        "occurred=" & Trim_Image (Identity.Times.Instant'Image (Event.Occurred_At)) & ";" &
        "recorded=" & Trim_Image (Identity.Times.Instant'Image (Event.Recorded_At)) & ";" &
        "severity=" & Identity.Events.Envelopes.Event_Severity'Image (Event.Severity) & ";" &
        "correlation=" & Identity.Identifiers.Operations.To_String (Event.Correlation) & ";" &
        "operation=" & Identity.Identifiers.Operations.To_String (Event.Operation) & ";" &
        "actor-kind=" & Identity.Events.Envelopes.Event_Actor_Kind'Image (Event.Actor.Kind) & ";" &
        "actor-principal=" & Actor_Principal_Image (Event.Actor) & ";" &
        "subject=" & Principal_Image (Event.Subject) & ";" &
        "outcome=" & Identity.Events.Envelopes.Event_Outcome'Image (Event.Outcome) & ";";
      Target : constant String := Identity.Text.Bounded.Image (Event.Target);
      Target_Length_Image : constant String := Trim_Image (Natural'Image (Target'Length));
      Target_Header_Template : constant String := "target-truncated=0;target-len=;target=";
      Target_Header_Length : constant Natural :=
        Target_Header_Template'Length + Target_Length_Image'Length;
      Available : constant Natural :=
        (if Prefix'Length + Target_Header_Length
             < Identity.Limits.Max_Public_Text_Bytes
         then Identity.Limits.Max_Public_Text_Bytes
              - Prefix'Length
              - Target_Header_Length
         else 0);
      Target_Used : constant Natural :=
        (if Target'Length <= Available then Target'Length else Available);
      Truncated : constant Boolean := Target_Used < Target'Length;
      Framed : constant String :=
        Prefix &
        "target-truncated=" & (if Truncated then "1" else "0") & ";" &
        "target-len=" & Target_Length_Image & ";" &
        "target=" & Prefix_Of (Target, Target_Used);
   begin
      return Identity.Text.Bounded.From_String (Framed);
   end Encode;
end Identity.Events.Canonical;
