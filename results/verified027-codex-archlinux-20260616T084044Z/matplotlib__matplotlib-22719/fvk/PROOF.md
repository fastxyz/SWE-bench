# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Machine-check commands to run later

These commands are recorded for a future environment with K installed:

```sh
cd fvk
kompile mini-category.k --backend haskell
kast --backend haskell category-empty-spec.k
kprove category-empty-spec.k
```

Expected machine-check result after the future `kprove` run: `#Top`.

## Proof summary

The defect is a two-branch proof obligation over the predicate
`values.size and is_numlike` in `StrCategoryConverter.convert`, plus the
analogous `data.size and convertible` predicate in `UnitData.update`.

For empty normalized data, `values.size == 0`. In Python boolean semantics,
`0 and is_numlike` evaluates false even if `is_numlike` is true by vacuity.
Therefore the deprecated numeric pass-through branch is unreachable for empty
data. The converter falls through to `unit.update(values)`; for an empty
sequence there are no elements to reject, so update succeeds without adding
mapping entries, and vectorized mapping over the empty array returns an empty
converted result. This discharges PO-1.

For non-empty numeric-like data, `values.size > 0` and `is_numlike == true`, so
the branch condition remains true. The existing warning and numeric return path
are preserved. This discharges PO-2.

For non-empty categorical data, `is_numlike == false`; adding `values.size` does
not change the false conjunction. Accepted values still reach `UnitData.update`
and map categorically, while invalid mixed values still fail validation. This
discharges PO-3 and PO-4.

For empty update data, `data.size == 0`, so `data.size and convertible` is false
even if `convertible` is true by vacuity. The all-convertible informational log
is not emitted. This discharges PO-5.

For non-empty all-convertible update data, `data.size > 0` and
`convertible == true`, so the log branch remains reachable. This discharges
PO-6.

No public signature or dispatch shape changed, discharging PO-7 by static
compatibility audit.

## Claim-by-claim proof sketch

### CONVERT-EMPTY-VACUOUS-NUMERIC

The K initial state is `convert(0, true, true)` with empty warnings and logs.
The only matching empty conversion rule rewrites to `.K`, leaves warnings and
logs empty, sets status to `ok`, and keeps result size `0`. The non-empty
numeric rule is blocked by `requires N >Int 0`.

### CONVERT-NONEMPTY-NUMERIC

For `N >Int 0`, the non-empty numeric conversion rule rewrites
`convert(N, true, UPDATEOK)` to `.K`, prepends `deprecatedNumeric` to warnings,
sets status to `ok`, and sets result size to `N`. This matches the claim.

### CONVERT-NONEMPTY-CATEGORICAL

For `N >Int 0`, `convert(N, false, true)` matches the accepted categorical rule,
which terminates with empty warnings, status `ok`, and result size `N`.

### CONVERT-NONEMPTY-INVALID

For `N >Int 0`, `convert(N, false, false)` matches the invalid categorical
rule, which terminates with status `typeError` and no deprecated numeric
warning.

### UPDATE-EMPTY-CONVERTIBLE

`update(0, true)` matches the empty update rule. The non-empty all-convertible
log rule is blocked by `requires N >Int 0`, so logs remain empty.

### UPDATE-NONEMPTY-CONVERTIBLE

For `N >Int 0`, `update(N, true)` matches the non-empty all-convertible rule,
which prepends `allConvertible` to logs and terminates with status `ok`.

## Residual risk

This is a partial-correctness, constructed proof over a mini-category
abstraction. It does not prove total correctness, real NumPy behavior,
dateutil parsing, mapping order, or artist rendering integration. Those remain
test obligations. Test removal is not recommended unless a future environment
machine-checks these claims and broader integration coverage remains intact.
