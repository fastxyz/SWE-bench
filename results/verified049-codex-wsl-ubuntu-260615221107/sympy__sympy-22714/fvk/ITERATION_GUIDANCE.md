# ITERATION_GUIDANCE

Status: constructed, not machine-checked.

## Code Decision

Apply V2 rather than keeping V1 unchanged.

Reason: F-001 shows V1 did not fully discharge PO-002 because only the top-level
`im` call was forced to evaluate. The source now uses:

```python
with evaluate_context(True):
    if any(a.is_number and im(a) for a in coords):
        raise ValueError('Imaginary coordinates are not permitted.')
```

This is the minimal source change that makes the validation probe use the same
evaluation semantics as the normal path while preserving the surrounding point
constructor behavior.

## No Further Source Changes Recommended

No parser, `sympify`, or test changes are recommended. F-002 localizes the
failure to geometry validation, and PO-006 requires preserving the public API
and parser behavior.

No broader rewrite to `im(a).is_zero` is recommended. It would change
indeterminate numeric behavior by rejecting only values known to be nonzero,
whereas the pre-existing guard rejects truthy evaluated imaginary parts.

## Suggested Tests for a Future Non-Benchmark Pass

Do not add tests in this task. In a normal development pass, add tests for:

- `with evaluate(False): S('Point2D(Integer(1),Integer(2))')`.
- Direct construction `with evaluate(False): Point2D(Integer(1), Integer(2))`.
- Existing rejection behavior for `Point(3, I)` under normal and suppressed
  evaluation.
- A real numeric expression whose imaginary part needs internal helper
  simplification under the validation probe.

## Machine-Checking Follow-Up

Run the commands listed in `PROOF.md` in an environment with K installed. Until
then, all proof statements remain constructed, not machine-checked, and no test
removal should be performed.
