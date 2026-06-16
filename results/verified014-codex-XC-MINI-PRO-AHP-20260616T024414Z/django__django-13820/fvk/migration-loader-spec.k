requires "mini-migration-loader.k"

module MIGRATION-LOADER-SPEC
  imports MINI-MIGRATION-LOADER

  // SPEC-PROVENANCE:
  // - from_prompt: "Permit migrations in non-namespace packages that don't have __file__"
  //   => a regular package without __file__ still scans when __path__ is a list.
  claim <k> decide(fileMissing, pathList) => scan </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "I am NOT asking to allow namespace packages for apps' migrations"
  //   and "Namespace packages do not use an ordinary list for their __path__"
  //   => missing __file__ plus non-list __path__ remains unmigrated.
  claim <k> decide(fileMissing, pathOther) => unmigrated </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_code/comment: "Module is not a package (e.g. migrations.py)"
  //   => an object without package path is not scanned.
  claim <k> decide(fileMissing, pathAbsent) => unmigrated </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: test_load_module_file expects a migrations module file
  //   to be in unmigrated_apps.
  claim <k> decide(fileSet, pathAbsent) => unmigrated </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "does not change Django's behavior at all for normal Python environments"
  //   => ordinary package with __file__ and list __path__ continues to scan.
  claim <k> decide(fileSet, pathList) => scan </k> [all-path]
endmodule
