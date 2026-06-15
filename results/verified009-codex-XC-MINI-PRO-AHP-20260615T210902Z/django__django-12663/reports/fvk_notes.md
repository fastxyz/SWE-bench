# FVK Notes

## Decision

V1 stands unchanged. No additional source edit is justified by the FVK audit.

## Trace to Findings and Proof Obligations

F-001 identifies the original bug: a selected `ForeignKey` subquery exposed
`Col.field`/`output_field` (`User.id`) instead of `Col.target` (`C.owner`),
which sent a lazy model RHS through plain integer preparation. PO-001 proves the
V1 line change makes `Query.output_field` return the relation field. PO-002
proves that this result propagates through `Subquery._resolve_output_field()`.
PO-003 proves the resulting relation output field uses related exact lookup
normalization. Together, these obligations resolve F-001, so the V1 source
change is kept.

F-002 raised the only structural concern with V1: whether `self.select[0]` can
be assumed to have `.target`. PO-001 and PO-004 discharge that concern from
source structure: selected fields are produced as `Col` instances by the query
selection machinery, and nearby ORM code already consumes `query.select[0]` via
`.target`. No defensive fallback or broader refactor is needed.

F-003 checks for unintended behavior changes. PO-004 covers both frame cases:
non-relational selected columns where `target == output_field`, and the
annotation-only branch that V1 did not edit. Because PO-004 is discharged, there
is no follow-up compatibility patch.

F-004 records the benchmark's no-execution constraint. PO-005 is satisfied
because I did not run tests, Python, `kompile`, `kast`, or `kprove`, and the FVK
artifacts label the proof as constructed, not machine-checked. This finding
does not call for a code change; it only constrains confidence and test-removal
claims.

## Artifact Decisions

The requested five FVK Markdown artifacts were written under `fvk/`. I also
included `fvk/mini-django-query.k` and `fvk/query-output-field-spec.k` because
the FVK method requires a formal core and exact commands even when tooling is
not run.

No test files were read for modification or edited. No source files beyond the
existing V1 change were edited during the FVK pass.
