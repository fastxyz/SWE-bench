# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Distinct marker contains a trailing separator

Statement: when `self.distinct` is true, the SQL context value for `%(distinct)s` is exactly `DISTINCT `.

Source: E-2 and `repo/django/db/models/aggregates.py`.

Discharged by: V1 source line `extra_context['distinct'] = 'DISTINCT ' if self.distinct else ''`; K rule `distinctMarker(true) => "DISTINCT "`.

Related findings: F-1.

## PO-2: Aggregate template concatenation produces `DISTINCT CASE`, not `DISTINCTCASE`

Statement: for template `%(function)s(%(distinct)s%(expressions)s)`, function `COUNT`, distinct marker `DISTINCT `, and expression SQL beginning `CASE`, the resulting SQL is `COUNT(DISTINCT CASE ...)`.

Source: E-4 and E-5.

Discharged by: K claim C-1 in `aggregate-spec.k`.

Related findings: F-1.

## PO-3: Non-distinct rendering is preserved

Statement: when `self.distinct` is false, the distinct marker is empty and no additional space is inserted after the opening parenthesis.

Source: I-3.

Discharged by: K rule `distinctMarker(false) => ""` and K claim C-2.

Related findings: F-3.

## PO-4: Filter fallback path preserves the fixed marker

Statement: when a backend lacks native aggregate `FILTER` support, `Aggregate.as_sql()` rewrites the filter into a `Case` expression and renders it with the already-fixed distinct context.

Source: E-3 and E-6.

Discharged by: source flow in `Aggregate.as_sql()` and K claim C-3.

Related findings: F-2.

## PO-5: Native aggregate `FILTER` path preserves the fixed marker

Statement: when a backend supports aggregate `FILTER`, the base aggregate inside the wrapper renders `COUNT(DISTINCT X)` before appending `FILTER (WHERE P)`.

Source: E-3 and `Aggregate.filter_template`.

Discharged by: source flow in `Aggregate.as_sql()` and K claim C-4.

Related findings: F-2.

## PO-6: Compatibility frame condition

Statement: V1 does not change public signatures, constructors, return shape, or non-distinct SQL rendering.

Source: I-4 and `PUBLIC_COMPATIBILITY_AUDIT.md`.

Discharged by: static diff showing only the internal true-branch string changed, plus K claim C-2 for non-distinct rendering.

Related findings: F-3 and F-4.

## PO-7: Adequacy gate

Statement: the formal claims must prove the public intent, not merely restate candidate behavior.

Source: FVK intent-evidence methodology.

Discharged by: `INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, and `SPEC_AUDIT.md`; the discriminator distinguishes `DISTINCTCASE` from `DISTINCT CASE`.

Related findings: F-5.

## PO-8: Machine-checking honesty gate

Statement: the proof is constructed but not machine-checked in this environment.

Source: user constraint forbidding K tooling and FVK verify honesty gate.

Discharged by: `PROOF.md` including exact commands and labeling the result constructed, not machine-checked.

Related findings: F-5.
