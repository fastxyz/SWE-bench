# Iteration Guidance

## Verdict

V1 stands unchanged.

The FVK audit localized the bug to the iterable branch dropping keyword-only
`cls` during recursive calls. V1 forwards `cls=cls` through that single
recursive call and leaves output shape, string/range parsing, and keyword
argument propagation unchanged.

## Code Guidance

Do not add a `Function` special case. The public docs describe `cls` as a
general constructor selector for symbol-like objects, and PO3 requires general
class preservation.

Do not refactor `symbols()` argument handling or merge `cls` into `args`. The
minimal source obligation is explicit recursive forwarding of keyword-only
`cls`.

Do not change tests in this benchmark. Hidden/public fixed tests should be able
to check the corrected behavior through the production code.

## Suggested Future Tests

Future maintainers should add or keep coverage for:

```python
q, u = symbols(('q:2', 'u:2'), cls=Function)
assert isinstance(q[0], FunctionClass)
```

and a general custom-class case, for example nested range input with
`cls=Dummy` or `cls=Wild`, to guard against treating the issue as
Function-specific.

## Residual Risk

The proof is constructed, not machine-checked. It also focuses on the issue's
observable properties: propagated constructor class and nested output shape.
Invalid-input error behavior and termination are outside this audit and remain
unchanged.
