# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Avg Accepts Distinct

Intent source: I1 and I2 in `SPEC.md`.

Formal claim: `init(Avg, true) => Obj(true)`.

Source facts:

- `Aggregate.__init__()` raises only if `distinct` is true and
  `allow_distinct` is false.
- `Avg` defines `allow_distinct = True`.

Obligation: for any `Avg` construction where the only questioned condition is
`distinct=True`, the rejection branch is unreachable and the object records
`distinct=True`.

Status: discharged by inspection of V1 source.

## PO-2: Sum Accepts Distinct

Intent source: I1 and I2 in `SPEC.md`.

Formal claim: `init(Sum, true) => Obj(true)`.

Source facts:

- `Aggregate.__init__()` raises only if `distinct` is true and
  `allow_distinct` is false.
- `Sum` defines `allow_distinct = True`.

Obligation: for any `Sum` construction where the only questioned condition is
`distinct=True`, the rejection branch is unreachable and the object records
`distinct=True`.

Status: discharged by inspection of V1 source.

## PO-3: Distinct State Reaches SQL

Intent source: I3 in `SPEC.md`.

Formal claims:

- `asSql("AVG", true, E) => Sql("AVG(DISTINCT " + E + ")")`
- `asSql("SUM", true, E) => Sql("SUM(DISTINCT " + E + ")")`

Source facts:

- `Aggregate.template` contains `%(distinct)s`.
- `Aggregate.as_sql()` sets `extra_context['distinct']` from `self.distinct`.
- The filter and non-filter paths both use that `extra_context`.

Obligation: after PO-1 or PO-2 constructs an aggregate with `self.distinct =
True`, SQL rendering includes the `DISTINCT ` fragment.

Status: discharged by inspection of existing shared aggregate code.

## PO-4: Existing Behavior Is Preserved Outside the Intended Change

Intent source: I1, I2, I4, and compatibility audit in `SPEC.md`.

Formal claims:

- `init(Max, true) => TypeError("does not allow distinct")`
- `init(Min, true) => TypeError("does not allow distinct")`

Source facts:

- V1 edits only `Avg.allow_distinct` and `Sum.allow_distinct`.
- `Aggregate.allow_distinct` remains false by default.
- `Count.allow_distinct` remains true.

Obligation: the fix does not weaken the opt-in model for other aggregate
subclasses or alter `Count`.

Status: discharged by the minimal diff.

## PO-5: Min and Max Scope Decision

Intent source: I4 in `SPEC.md`.

Obligation: prove that leaving `Min` and `Max` unchanged is not a failure
against the public issue.

Reasoning: the public issue says the change "could" be applied to `Min` and
`Max`, not that it must be applied. The title and concrete bug text identify
`Avg` and `Sum` as the required aggregates. Because `DISTINCT` is semantically
pointless for extrema, adding it would expand public behavior without a
mandatory requirement.

Status: discharged as a scope proof, not a runtime proof.

## PO-6: Verification Honesty

Intent source: FVK docs and benchmark no-execution rule.

Obligation: do not claim machine verification, do not remove tests, and write
the commands that would be run later.

Status: discharged in `PROOF.md`.
