requires "mini-python-autofield.k"

module AUTOFIELD-META-SPEC
  imports MINI-PYTHON-AUTOFIELD
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "DEFAULT_AUTO_FIELD subclass check fails for subclasses of
  //   BigAutoField and SmallAutoField." => subclasses of each compatibility
  //   root must satisfy issubclass(C, AutoField).
  // - from_code: AutoFieldMeta._subclasses is (BigAutoField, SmallAutoField).
  claim <k> autoFieldSubclassCheck(C:Class) => true </k>
    requires subclassOf(C, bigAutoField) ==Bool true
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: same family obligation for SmallAutoField.
  // - from_code: AutoFieldMeta._subclasses is (BigAutoField, SmallAutoField).
  claim <k> autoFieldSubclassCheck(C:Class) => true </k>
    requires subclassOf(C, smallAutoField) ==Bool true
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/comment: AutoFieldMeta maintains backward inheritance
  //   compatibility for AutoField and still delegates to super().
  // - frame condition: direct AutoField subclasses remain accepted.
  claim <k> autoFieldSubclassCheck(C:Class) => true </k>
    requires subclassOf(C, autoField) ==Bool true
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: non-AutoField DEFAULT_AUTO_FIELD values raise
  //   ValueError.
  // - frame condition: classes outside AutoField/BigAutoField/SmallAutoField
  //   inheritance remain rejected.
  claim <k> autoFieldSubclassCheck(C:Class) => false </k>
    requires subclassOf(C, bigAutoField) ==Bool false
     andBool subclassOf(C, smallAutoField) ==Bool false
     andBool subclassOf(C, autoField) ==Bool false
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: custom BigAutoField subclass used as DEFAULT_AUTO_FIELD
  //   must not raise "must subclass AutoField".
  claim <k> defaultPkCheck(imported(customBigAutoField)) => accepted(customBigAutoField) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: issue also names SmallAutoField subclasses.
  claim <k> defaultPkCheck(imported(customSmallAutoField)) => accepted(customSmallAutoField) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt/hint: "subclasses of those classes in the _subclasses
  //   property" means transitive subclassing, not exact/direct membership only.
  claim <k> defaultPkCheck(imported(indirectCustomBigAutoField)) => accepted(indirectCustomBigAutoField) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: DEFAULT_AUTO_FIELD='django.db.models.TextField'
  //   must continue to raise ValueError.
  claim <k> defaultPkCheck(imported(textField)) => valueError </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: nonexistent and empty DEFAULT_AUTO_FIELD handling
  //   are separate validation branches and must be preserved.
  claim <k> defaultPkCheck(importError) => improperlyConfigured </k>
    [all-path]

  claim <k> defaultPkCheck(emptyPath) => improperlyConfigured </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: this is the pre-fix defect witness. Exact membership rejects
  //   customBigAutoField even though the subclass-aware contract accepts it.
  claim <k> legacyExactTupleCheck(customBigAutoField) => false </k>
    [all-path]
endmodule
