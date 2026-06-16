# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a source-code problem that
requires a V2 edit.

## Trace to findings and obligations

`fvk/FINDINGS.md` F1 identifies the original defect: a full predicate from
`~Q(pk__in=[])` reached `When.as_sql()` as an empty SQL string and produced
`WHEN  THEN`. `fvk/PROOF_OBLIGATIONS.md` O1, O2, and O4 cover the required
repair: recognize the full-predicate sentinel, render it as a valid always-true
predicate, and produce `CASE WHEN 1=1 THEN True ELSE False END` for the issue
shape. The existing V1 edit in `repo/django/db/models/expressions.py` satisfies
those obligations directly:

```python
if condition_sql == "":
    condition_sql = "1=1"
```

F2 and O3 cover the main regression risk: `When(pk__in=[])` must remain an
impossible predicate that falls through to the `Case` default. V1 does not catch
`EmptyResultSet`, so the existing `Case.as_sql()` skip behavior remains intact.
No code edit was needed.

F3 and O5-O7 cover compatibility: non-empty predicate SQL remains unchanged,
parameter ordering is preserved, and `When.as_sql()` keeps the same signature
and return shape. The audit found no public callsite or override requiring a
source change.

F4 and O8 record the residual verification boundary. The proof artifacts are
constructed, not machine-checked, and this session forbids running tests,
Python, or K tooling. That limitation justifies keeping tests and recording the
commands, but it does not justify changing the source beyond the already
derived V1 fix.

## Artifacts written

The requested FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK support and adequacy artifacts are:

- `fvk/mini-django-case.k`
- `fvk/django-case-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

No test files were modified, and no commands that execute project code or K
tooling were run.
