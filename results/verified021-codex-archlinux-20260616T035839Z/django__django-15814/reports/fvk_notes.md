# FVK Notes

Status: constructed, not machine-checked.

## Decisions

### Keep the V1 source fix unchanged

Decision: no additional edit was made to `repo/django/db/models/sql/query.py`.

Trace:

- `fvk/FINDINGS.md` `F1` localizes the bug to a proxy/concrete key split in
  deferred-loading masks.
- `fvk/PROOF_OBLIGATIONS.md` `PO2` requires storing the related primary key
  under `T._meta.concrete_model`.
- `fvk/PROOF_OBLIGATIONS.md` `PO3` requires the requested related field and the
  required primary key to merge under the same concrete model key.
- The existing V1 line `cur_model = cur_model._meta.concrete_model` discharges
  those obligations before `opts` and `must_include` are updated.

### Reject a later consumer special case

Decision: do not change `SQLCompiler.get_default_columns()` or
`RelatedPopulator`.

Trace:

- `fvk/FINDINGS.md` `F1` shows the bad state is created before those consumers:
  `id` is stored under the proxy key while `name` is stored under the concrete
  key.
- `fvk/PROOF_OBLIGATIONS.md` `PO4` requires producer and consumer key
  compatibility, which is better satisfied by fixing mask construction than by
  adding proxy-specific lookup behavior later.

### Preserve non-proxy behavior

Decision: do not refactor the surrounding loop or merge logic.

Trace:

- `fvk/FINDINGS.md` `F3` and `fvk/PROOF_OBLIGATIONS.md` `PO5` state the frame
  condition for non-proxy targets.
- The formal claim `CONCRETE-TARGET-FRAME` in `fvk/django-deferred-spec.k`
  models `concrete(customModel) = customModel`, so V1 is an identity for
  concrete targets.

### Keep tests untouched

Decision: no test file was modified.

Trace:

- The task forbids modifying tests.
- `fvk/FINDINGS.md` `F4` records that tests and K tooling were not run in this
  workspace.
- `fvk/ITERATION_GUIDANCE.md` records the regression test shape to add when test
  edits are allowed.

## Artifacts written

Required artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Supporting FVK artifacts required by the kit documentation:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python.k`
- `fvk/django-deferred-spec.k`

## Execution note

No tests, Python, `kompile`, `kast`, or `kprove` commands were run. The exact
commands to run later are recorded in `fvk/PROOF.md`.
