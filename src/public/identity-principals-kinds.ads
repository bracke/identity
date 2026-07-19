package Identity.Principals.Kinds is
   pragma Pure;
   type Principal_Kind is (Human, Service, System);

   function Human_Principal (Kind : Principal_Kind) return Boolean is
     (Kind = Human);

   function Service_Principal (Kind : Principal_Kind) return Boolean is
     (Kind = Service);

   function System_Principal (Kind : Principal_Kind) return Boolean is
     (Kind = System);
end Identity.Principals.Kinds;
