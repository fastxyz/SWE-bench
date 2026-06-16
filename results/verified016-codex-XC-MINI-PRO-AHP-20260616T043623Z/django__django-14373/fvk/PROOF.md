# FVK Proof

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Claims Proved By Construction

`DATEFORMAT-Y`: for any integer date year `Y` with `1 <= Y <= 9999`, evaluating
the modeled V1 body of `DateFormat.Y()` reaches `yearText(4, Y)`, meaning a
four-visible-character representation of the numeric year `Y`.

`FORMAT-Y`: for any integer date year `Y` with `1 <= Y <= 9999`, evaluating the
modeled single-specifier formatting path for `"Y"` reaches the same
`yearText(4, Y)` result.

No loop circularity is needed for `DateFormat.Y()` because the method body is a
single return expression. The dispatcher loop is not the source of the defect
and is modeled only for the single `Y` specifier path relevant to the public
issue.

## Symbolic Proof Sketch

1. Start in a state with `obj.year = Y` and side condition
   `1 <= Y <= 9999`.
2. The `DateFormat.Y()` body evaluates `self.data.year`, yielding `Y`.
3. The `%04d` formatting operation is modeled by `pad4(Y)`.
4. The mini semantics rule for `pad4` rewrites `pad4(Y)` to `yearText(4, Y)`
   under the date-year side condition.
5. Therefore `DateFormat.Y()` reaches `yearText(4, Y)`, discharging PO-01,
   PO-03, and PO-04.
6. For `format(obj, "Y")`, `Formatter.format()` selects the `Y` method, invokes
   it, and stringifies the result. The invoked method has already reached
   `yearText(4, Y)`, so the single-specifier output reaches the same observable
   padded text, discharging PO-02.
7. The source diff touches no other formatter methods or dispatcher logic,
   discharging PO-05 and PO-06 by frame/source inspection.

## Verification Conditions

VC-01: Date-year domain.

`1 <= Y <= 9999` is the precondition for applying the `pad4` rule. This matches
the supported Python `date`/`datetime` year domain used by Django's date
formatter.

VC-02: Padding boundary.

For `1 <= Y <= 999`, `%04d` produces leading zeroes until the visible length is
4. This is the central issue obligation and is modeled as `yearText(4, Y)`.

VC-03: Four-digit preservation.

For `1000 <= Y <= 9999`, `%04d` leaves the visible decimal representation at
length 4 and preserves numeric value `Y`.

VC-04: Dispatcher exposure.

`Formatter.format()` exposes the selected formatter method result via `str()`.
Since `DateFormat.Y()` already returns the intended text, no dispatcher change is
needed.

## Machine-Check Commands Not Run

These commands are recorded for a future environment with K installed. They were
not executed in this benchmark session.

```sh
cd fvk
kompile mini-dateformat.k --backend haskell
kast --backend haskell dateformat-y-spec.k
kprove dateformat-y-spec.k
```

Expected result after a successful future machine check: `kprove` returns
`#Top` for the two claims.

## Test Redundancy Recommendation

No tests should be removed in this benchmark session. If the K claims are later
machine-checked successfully, focused unit tests that only assert in-domain
examples of `format(obj, "Y")` for specific years would be logically subsumed by
the quantified contract. Boundary/integration tests should still be kept unless
a broader proof covers their full behavior.

## Residual Risk

The proof is constructed, not machine-checked. It depends on the adequacy of the
mini semantics for the `%04d` formatting operation and on the scoped decision
that the issue obligates `Y`, not every adjacent year-shaped specifier such as
`o`.
