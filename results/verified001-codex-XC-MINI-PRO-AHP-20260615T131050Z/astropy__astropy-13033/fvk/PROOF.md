# FVK Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## What Is Proved

For every audited `BaseTimeSeries` state in the domain of `SPEC.md`, V1 satisfies
the required-column validation contract:

- disabled checks and `None` required-column contracts do not raise;
- active required prefixes are computed according to relaxed/non-relaxed mode;
- invalid single-column failures keep the legacy scalar message;
- invalid multi-column failures display the full active required prefix and the
  found prefix of the same length;
- valid prefixes do not raise and still clear relaxed mode once the full
  required prefix is present.

The proof is partial correctness for this straight-line branching method. There
are no loops or recursive calls in the audited unit.

## Mini Semantics Summary

The model state is:

```text
State(class_name, enabled, req_option, relax, cols)
```

The semantics for `check(State)` is a deterministic case split:

1. If `enabled` is false, return `ok(relax)`.
2. If `req_option` is `None`, return `ok(relax)`.
3. Let `active = req[:len(cols)]` when `relax` is true, else `req`.
4. If not relaxed and `cols` is empty:
   - if `len(active) == 1`, return `error(singleNoColumns(...))`;
   - otherwise return `error(multiNoColumns(...))`.
5. If `cols[:len(active)] != active`:
   - if `len(active) == 1`, return `error(singleFound(...))`;
   - otherwise return `error(multiFound(active, cols[:len(active)]))`.
6. Otherwise return `ok(relax')`, where `relax'` is false exactly when the full
   required prefix is now present.

This semantics keeps the observable axis of the issue: ordered list prefixes and
message content.

## Symbolic Case Proof

PO-001 and PO-002 discharge immediately by the first guards in the source:
`_required_columns_enabled` false returns before any message logic, and
`_required_columns is None` skips the whole validation block.

For PO-003, assume `enabled == True`, `req` is not `None`,
`relax == False`, and `cols == []`. Source control reaches the no-columns
branch. V1 then splits on `len(required_columns) == 1`. The first branch formats
the legacy scalar message; the second formats the required list. This matches
RC-NONRELAX-EMPTY-SINGLE and RC-NONRELAX-EMPTY-MULTI.

For PO-004, assume `active` has length one and `cols[:1] != active`. Source
control reaches the prefix-mismatch branch and selects the scalar branch. The
message contains `active[0]` and `cols[0]`, matching the compatibility claim.

For PO-005, assume `active` has length greater than one and
`cols[:len(active)] != active`. Source control reaches the prefix-mismatch
branch and selects the multi-column branch. The message contains `active` and
`cols[:len(active)]`. Therefore the reproduction with
`active == ['time', 'flux']` and `cols == ['time']` reaches:

```text
TimeSeries object is invalid - required ['time', 'flux'] as the first columns
but found ['time']
```

This is the issue's expected form.

For PO-006, assume the prefix comparison succeeds. Neither error branch fires.
The only remaining state mutation is the preserved relaxed-mode toggle:
`_required_columns_relax` becomes false exactly when the full required prefix is
present.

For PO-007 and PO-008, the diff leaves the wrapper, method list, signatures, and
success predicates unchanged. Therefore all previous mutation call paths still
reach `_check_required_columns()`, and the behavior change is limited to the
intended multi-column error observable.

## Pre-Fix Symptom Derivation

The pre-fix code used `required_columns[0]` and `self.colnames[0]` for every
prefix mismatch. In the issue reproduction after `remove_column("flux")`, the
comparison was:

```text
['time'] != ['time', 'flux']
```

but the displayed scalar fields were:

```text
required_columns[0] == 'time'
self.colnames[0] == 'time'
```

So the pre-fix mechanism directly produces the reported symptom:
`expected 'time' ... found 'time'`. V1 removes that mechanism for
multi-column active requirements by formatting the list values instead.

## Verification Commands

These commands were not run:

```sh
kompile fvk/mini-required-columns.k --backend haskell
kast --backend haskell fvk/required-columns-spec.k
kprove fvk/required-columns-spec.k
```

Expected machine-check result after a successful proof: `#Top`.

## Test Guidance

No test removal is justified. Even if the constructed proof were later
machine-checked, public tests around exact exception messages should be kept
unless maintainers intentionally replace them with tests covering the new
multi-column behavior. The proof is unit-level and does not cover integration,
termination, or performance behavior.

## Residual Risk

The proof is constructed by source inspection and symbolic case analysis, not by
executing `kprove`. It relies on the adequacy of the mini model for Python list
slicing, equality, and string formatting. This is sufficient to audit the V1
source decision under the task constraints, but it is not a machine-checked K
result.
