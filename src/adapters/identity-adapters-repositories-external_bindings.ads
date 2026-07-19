with Identity.External_Providers.Bindings;
with Identity.Identifiers.Entities;
with Identity.Versions;

package Identity.Adapters.Repositories.External_Bindings is
   pragma Pure;

   type External_Binding_Read_Status is (Found, Not_Found, Replay_Detected, Capacity_Exceeded, Infrastructure_Failure);

   function Found_Status (Status : External_Binding_Read_Status) return Boolean is
     (Status = Found);

   function Missing_Status (Status : External_Binding_Read_Status) return Boolean is
     (Status = Not_Found);

   function Replay_Detected_Status (Status : External_Binding_Read_Status) return Boolean is
     (Status = Replay_Detected);

   function Capacity_Rejected (Status : External_Binding_Read_Status) return Boolean is
     (Status = Capacity_Exceeded);

   function Infrastructure_Failed (Status : External_Binding_Read_Status) return Boolean is
     (Status = Infrastructure_Failure);

   function Operational_Failure (Status : External_Binding_Read_Status) return Boolean is
     (Status in Capacity_Exceeded | Infrastructure_Failure);

   function Security_Response_Required (Status : External_Binding_Read_Status) return Boolean is
     (Status = Replay_Detected);

   type External_Binding_View is record
      Status      : External_Binding_Read_Status := Not_Found;
      Binding_Id  : Identity.Identifiers.Entities.External_Binding_Id;
      Binding     : Identity.External_Providers.Bindings.External_Binding_Record;
      Version     : Identity.Versions.Entity_Version := 0;
   end record;
end Identity.Adapters.Repositories.External_Bindings;
