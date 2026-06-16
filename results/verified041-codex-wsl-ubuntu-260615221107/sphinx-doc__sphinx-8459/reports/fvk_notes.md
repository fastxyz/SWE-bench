# FVK Notes

## Decision summary

V1 stands unchanged. The FVK audit did not identify a source-level defect that would
justify a V2 edit.

## Trace from findings and proof obligations

* `F1` and `PO1` identify the root defect as alias-unaware recording in
  `record_typehints()`. V1 directly discharges this by calling
  `inspect.signature(obj, type_aliases=app.config.autodoc_type_aliases)`.
* `F1` and `PO2` require both parameter and return annotations to use alias-aware
  resolution. The existing post-signature recording logic iterates parameters and
  handles `sig.return_annotation`, so no additional source edit is needed once the
  signature object is alias-aware.
* `F2` and `PO3` confirm `merge_typehints()` / `modify_field_list()` preserve the
  recorded annotation string when inserting `type NAME` and `rtype` fields. I rejected
  a merge-layer change because it would duplicate alias resolution after annotations
  have already been stringified.
* `F3` and `PO5` confirm the V1 change preserves public compatibility: the autodoc
  event callback signature and `app.env.temp_data['annotations']` shape are unchanged.
* `F4` and `PO6` record the residual proof/tooling risk. Because execution is
  forbidden, the K proof remains constructed rather than machine-checked, and no tests
  should be removed or modified.

## Artifacts written

Required task artifacts:

* `fvk/SPEC.md`
* `fvk/FINDINGS.md`
* `fvk/PROOF_OBLIGATIONS.md`
* `fvk/PROOF.md`
* `fvk/ITERATION_GUIDANCE.md`

Additional FVK adequacy and formal-core artifacts required by the method docs:

* `fvk/INTENT_SPEC.md`
* `fvk/PUBLIC_EVIDENCE_LEDGER.md`
* `fvk/FORMAL_SPEC_ENGLISH.md`
* `fvk/SPEC_AUDIT.md`
* `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
* `fvk/mini-python-autodoc.k`
* `fvk/autodoc-typehints-spec.k`

## Execution status

No tests, Python code, `kompile`, `kast`, or `kprove` commands were run. The commands
needed for future machine checking are recorded in `fvk/PROOF.md`.
