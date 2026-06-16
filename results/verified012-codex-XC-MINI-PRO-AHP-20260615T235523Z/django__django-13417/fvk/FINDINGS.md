# FVK Findings

Status: constructed, not machine-checked. These findings are based on public
intent, source inspection, and constructed proof obligations only.

## F1 - Pre-V1 grouped default-ordering mismatch

Classification: code bug found by the public issue; fixed by V1.

Input:

```text
isEmpty = false
hasExtraOrderBy = false
hasExplicitOrderBy = false
defaultOrderingEnabled = true
hasMetaOrdering = true
hasGroupBy = true
```

Observed before V1: `QuerySet.ordered` returned `True` because it treated
`Meta.ordering` as sufficient whenever default ordering was enabled.

Expected: `False`, because the compiler suppresses default `Meta.ordering` when
`GROUP BY` is emitted.

Trace: E1, E2, E3, PO-1, PO-4, `GROUPED-META-UNORDERED`.

## F2 - Explicit grouped ordering remains valid

Classification: non-regression obligation; no code bug in V1.

Input:

```text
isEmpty = false
hasExplicitOrderBy = true
hasGroupBy = true
```

Expected and V1 behavior: `True`. The compiler suppression rule applies only to
default `_meta_ordering`, not explicit `query.order_by` or `extra_order_by`.

Trace: E4, E5, PO-3, `EXPLICIT-GROUPED-ORDERED`.

## F3 - No public API compatibility issue

Classification: compatibility audit.

Observed: V1 changes only the default-ordering boolean condition. The
`QuerySet.ordered` symbol remains a no-argument property returning a boolean, and
source callsites read it as a property.

Expected: no caller or override changes.

Trace: E7, PO-7, `PUBLIC_COMPATIBILITY_AUDIT.md`.

## F4 - Constructed proof is not machine-checked

Classification: proof capability and test policy gap, not a source bug.

Observed: The FVK proof and K artifacts were constructed, but `kompile`,
`kast`, `kprove`, Python, and tests were not run by instruction.

Expected: Do not remove or weaken tests based on this proof. If K tooling is
available later, run the emitted commands and require `kprove` to return `#Top`
before treating proof-subsumed tests as redundant.

Trace: PO-8 and `PROOF.md`.

## F5 - V1 stands after FVK audit

Classification: repair decision.

Observed: The proof obligations cover the reported grouped default-ordering
case, explicit ordering preservation, non-grouped default ordering preservation,
empty querysets, and no-ordering states. No proof obligation or adequacy check
surfaced a remaining source mismatch.

Expected: No V2 source edit is justified beyond V1.

Trace: PO-1 through PO-8.
