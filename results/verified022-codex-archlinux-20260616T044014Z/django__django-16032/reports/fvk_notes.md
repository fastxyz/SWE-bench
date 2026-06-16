# FVK Notes

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Production Code Decision

No V2 production-code edits were made. V1 stands.

## Decision Trace

D-001: Keep `Query.has_select_fields` as explicit state defaulting to `False`
and set by `Query.set_values()`.

- Findings: F-001, F-004.
- Proof obligations: PO-001, PO-002, PO-006, PO-007.
- Reason: the issue requires `annotate().alias()` without `values()` to remain
  an undefined RHS selected-field state so base `In` and `Exact` narrow to pk.
  It also requires real values-style selections to be preserved.

D-002: Keep the `RelatedIn.get_prep_lookup()` change from `add_fields()` to
`set_values([target_field])`.

- Findings: F-002.
- Proof obligations: PO-003.
- Reason: with `has_select_fields` no longer inferred from `select`, using
  `add_fields()` would leave the flag false and allow base `In` to overwrite the
  related target field with pk.

D-003: Do not add an explicit `Query.clone()` assignment.

- Findings: F-003.
- Proof obligations: PO-004.
- Reason: `set_values()` writes `has_select_fields` as instance state, and
  `Query.clone()` already copies instance state with `__dict__.copy()`.

D-004: Do not change base `In.get_prep_lookup()` or `Exact.get_prep_lookup()` to
use `set_values(["pk"])`.

- Findings: F-004.
- Proof obligations: PO-002, PO-006.
- Reason: automatic pk injection is lookup defaulting for an undefined RHS
  selected-field state. It should not be treated as user explicit selection.
  The one downstream overwrite risk identified by the audit is already fixed in
  `RelatedIn`.

D-005: Do not make compatibility or test-file edits.

- Findings: F-005, F-006.
- Proof obligations: PO-005.
- Reason: V1 changes private ORM state handling and one internal related lookup
  preparation call only. The benchmark forbids test edits and code execution,
  and the constructed proof does not justify deleting tests.

## Artifact Changes

Added the requested FVK Markdown artifacts under `fvk/`:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Added constructed K sidecars required by the FVK method:

- `fvk/mini-django-query.k`
- `fvk/query-in-spec.k`

These sidecars were written but not executed.
