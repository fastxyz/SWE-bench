# Iteration Guidance

## Verdict

V1 stands unchanged. The FVK audit found the reported defect resolved and did not surface a new source-code issue.

## Source Decision

No further edit to `repo/sympy/core/numbers.py` is justified. The current `qden` accumulator satisfies PO1 and PO2, and the downstream constructor branches satisfy the frame obligations PO4 through PO7.

## Future Tests to Add Outside This Task

Do not edit tests in this benchmark task. In a normal development setting, add tests equivalent to:

```python
for p in ('1.5', 1.5, 2):
    for q in ('1.5', 1.5, 2):
        assert Rational(p, q).as_numer_denom() == Rational('%s/%s' % (p, q)).as_numer_denom()
```

Also add the concrete regression case:

```python
assert Rational('0.5', '100') == Rational(1, 200)
```

## Future Verification

Run the recorded commands in `fvk/PROOF.md` in an environment with K installed. Keep proof-subsumed tests until `kprove` returns `#Top`.

## No Open FVK Repair Items

The only residual item is the honesty gap that the proof is constructed rather than machine-checked in this session.
