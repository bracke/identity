package Identity.Adapters.Repositories is
   pragma Pure;

   type Context_State is (Opened, Transaction_Active, Committed, Rolled_Back, Closed, Faulted);
   type Transaction_Mode is (Read_Only, Read_Write, Security_Transition);

   function Is_Open (State : Context_State) return Boolean is
     (State = Opened);

   function In_Transaction (State : Context_State) return Boolean is
     (State = Transaction_Active);

   function Is_Committed (State : Context_State) return Boolean is
     (State = Committed);

   function Is_Rolled_Back (State : Context_State) return Boolean is
     (State = Rolled_Back);

   function Is_Closed (State : Context_State) return Boolean is
     (State = Closed);

   function Is_Faulted (State : Context_State) return Boolean is
     (State = Faulted);

   function Finalized (State : Context_State) return Boolean is
     (State in Committed | Rolled_Back | Closed | Faulted);

   function May_Begin_Transaction (State : Context_State) return Boolean is
     (State = Opened);

   function May_Commit (State : Context_State) return Boolean is
     (State = Transaction_Active);

   function May_Rollback (State : Context_State) return Boolean is
     (State = Transaction_Active);
end Identity.Adapters.Repositories;
