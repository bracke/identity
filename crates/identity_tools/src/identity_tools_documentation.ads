package Identity_Tools_Documentation is
   pragma Elaborate_Body;

   --  Documentation release gate.
   --
   --  Checks that the shipped documentation set is complete, non-empty, free of
   --  unresolved placeholder markers, that every documentation artifact named in
   --  registries/release-artifacts.json exists, that every public package family
   --  under src/public is named in docs/ai/package-map.md, and that CHANGELOG.md
   --  carries a section for the crate version declared in alire.toml.

   type Validation_Report is record
      Documents_Checked         : Natural := 0;
      Required_Documents        : Natural := 0;
      Missing_Required          : Natural := 0;
      Empty_Required            : Natural := 0;
      Referenced_Documents      : Natural := 0;
      Missing_Referenced        : Natural := 0;
      Artifact_Documents        : Natural := 0;
      Missing_Artifact_Docs     : Natural := 0;
      Placeholder_Hits          : Natural := 0;
      Public_Areas              : Natural := 0;
      Unmapped_Areas            : Natural := 0;
      Missing_Changelog_Section : Natural := 0;
   end record;

   procedure Validate (Report : out Validation_Report);
   function Passed (Report : Validation_Report) return Boolean;
end Identity_Tools_Documentation;
