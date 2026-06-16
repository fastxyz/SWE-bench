# Constructed Proof

Status: constructed, not machine-checked.

## Claims Proved in the Model

The formal core is in:

- `fvk/mini-python.k`
- `fvk/select-date-widget-spec.k`

The claims are:

- `EMPTY-TRIPLE`: all three split components present and blank return `noneResult()`.
- `PARTIAL-FALLBACK-Y`, `PARTIAL-FALLBACK-M`, `PARTIAL-FALLBACK-D`: any missing split component falls back to the legacy `data.get(name)` value.
- `VALID-COMPLETE`: valid complete triples return a formatted date result.
- `VALUE-ERROR-COMPLETE`: complete triples classified as `ValueError` invalid dates return `pseudoDate(Y, M, D)`.
- `OVERFLOW-COMPLETE`: complete triples classified as `OverflowError` invalid dates return `pseudoDate(Y, M, D)`.

## Proof Sketch

There are no loops or recursive calls, so no circularity is needed.

The proof is by case analysis over the method's branch order.

1. All-empty branch: if `y`, `m`, and `d` are all `""`, the first guard returns `None`. This discharges PO-004 and the `EMPTY-TRIPLE` claim.
2. Complete-triple branch: if all three component keys are present and the all-empty guard did not fire, the method computes `input_format` and enters the `try`.
3. Valid complete triple: if `datetime.date(int(y), int(m), int(d))` succeeds, control skips the `except` handler and returns `date_value.strftime(input_format)`. This discharges PO-003 and the `VALID-COMPLETE` claim.
4. `ValueError` complete triple: if integer conversion or date construction raises `ValueError`, the existing handler returns the pseudo-ISO expression. This discharges PO-002 and the `VALUE-ERROR-COMPLETE` claim.
5. `OverflowError` complete triple: if date construction raises `OverflowError`, V1's expanded exception tuple selects the same handler and returns the same pseudo-ISO expression. The exception cannot escape that `try` block. This discharges PO-001 and the `OVERFLOW-COMPLETE` claim.
6. Missing-component branch: if any component is absent, the complete-triple branch is skipped and the final return gives `data.get(name)`. This discharges PO-005 and the partial-fallback claims.
7. Compatibility: no branch outside the `except` selector changed, and no public signature changed. This discharges PO-006.

## Machine Check Commands

These commands are emitted for future verification only. They were not run.

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell select-date-widget-spec.k
kprove select-date-widget-spec.k
```

Expected future result after a successful machine check: `#Top` for all claims.

## Residual Risk

The mini semantics abstracts Django's date formatting and Python's date constructor into classification predicates. That is adequate for the audited property because the defect is the branch selection for `ValueError` versus `OverflowError`, and the model keeps that distinction observable. The proof does not model arbitrary non-request mapping objects or failures outside the public issue path, such as exceptions from `data.get()`, formatting configuration lookup, or custom object conversion.

The proof is partial correctness. Since the audited code has no loop or recursion, there is no separate termination argument beyond straight-line branch completion in the modeled fragment.

## Test Guidance

No tests were edited. If machine-checking later succeeds, focused unit tests that only restate the modeled branch outputs are candidates for redundancy, but integration tests for form binding should be kept. Add or keep a regression test for an oversized year, and preferably oversized month/day as well, because those are the public bug boundary cases.

