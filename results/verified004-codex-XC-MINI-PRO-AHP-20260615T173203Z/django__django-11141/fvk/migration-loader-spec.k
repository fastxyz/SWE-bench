requires "mini-loader.k"

module MIGRATION-LOADER-SPEC
  imports MINI-LOADER

  // SPEC-PROVENANCE:
  // - from_prompt: "Allow migrations directories without __init__.py files"
  //   => namespace packages with __path__ are migrated.
  // - from_prompt: "__file__ check is no longer needed"
  //   => HAS_FILE must not affect the classifier when HAS_PATH is true.
  claim <k> classify(loaded(true, false, ENTRIES:List))
        => migrated(filterNames(ENTRIES)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "pkgutil.iter_modules() uses the package's __path__ list"
  //   => regular packages and namespace packages share path-based discovery.
  claim <k> classify(loaded(true, true, ENTRIES:List))
        => migrated(filterNames(ENTRIES)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: "Module is not a package (e.g. migrations.py)."
  //   => modules without __path__ remain unmigrated.
  claim <k> classify(loaded(false, HAS_FILE:Bool, ENTRIES:List))
        => unmigrated </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: module_name is None means migrations disabled.
  claim <k> classify(disabled) => unmigrated </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: accepted missing module cases are unmigrated.
  claim <k> classify(missingOk) => unmigrated </k>
    [all-path]
endmodule
