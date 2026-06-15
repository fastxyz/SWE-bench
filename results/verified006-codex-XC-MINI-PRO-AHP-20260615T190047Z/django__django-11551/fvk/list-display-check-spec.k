requires "mini-admin-check.k"

module LIST-DISPLAY-CHECK-SPEC
  imports MINI-ADMIN-CHECK

  // SPEC-PROVENANCE:
  // - from_docs: list_display accepts callables.
  // - from_code: callable(item) is the first branch.
  claim [CALLABLE-OK]:
    <k> check(true, GF:Lookup, ADMIN:Bool, MA:Lookup) => ok </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: metadata-visible fields must not raise false admin.E108.
  // - from_docs: model fields are valid list_display items.
  claim [FIELD-REGULAR-OK]:
    <k> check(false, resolved(regular), ADMIN:Bool, MA:Lookup) => ok </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: descriptor-returned None must not be conflated with lookup failure.
  claim [FIELD-NONE-OK]:
    <k> check(false, resolved(noneValue), ADMIN:Bool, MA:Lookup) => ok </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: ManyToManyField fields are not supported.
  claim [FIELD-M2M-E109]:
    <k> check(false, resolved(m2m), ADMIN:Bool, MA:Lookup) => e109 </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: model fields are interpreted before same-named ModelAdmin attrs.
  // - from_runtime: lookup_field() tries model field lookup before admin fallback.
  claim [FIELD-M2M-ADMIN-PRECEDENCE-E109]:
    <k> check(false, resolved(m2m), true, MA:Lookup) => e109 </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: a string representing a ModelAdmin method is accepted.
  claim [ADMIN-ATTR-OK]:
    <k> check(false, missing, true, MA:Lookup) => ok </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: a string representing a model attribute/method is accepted.
  claim [MODEL-ATTR-REGULAR-OK]:
    <k> check(false, missing, false, resolved(regular)) => ok </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: a descriptor returning None must be accepted, not treated as missing.
  claim [MODEL-ATTR-NONE-OK]:
    <k> check(false, missing, false, resolved(noneValue)) => ok </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: any successful resolved field-like value must still be checked for ManyToManyField.
  // - from_docs: ManyToManyField fields are not supported.
  claim [MODEL-ATTR-M2M-E109]:
    <k> check(false, missing, false, resolved(m2m)) => e109 </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: E108 only when both metadata and attribute lookup fail.
  // - from_tests: missing field public test expects admin.E108.
  claim [MISSING-ALL-E108]:
    <k> check(false, missing, false, missing) => e108 </k>
    [all-path]
endmodule

