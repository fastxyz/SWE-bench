# FVK Findings

Status: no open production-code finding after V1. Proof is constructed, not
machine-checked.

## F1 - Closed Code Bug: Iterable Recursion Dropped `cls`

Input:

```python
symbols(('q:2', 'u:2'), cls=Function)
```

Observed pre-fix behavior by source trace: the outer iterable branch called
`symbols(name, **args)`. Since `cls` is keyword-only and not part of `args`, the
recursive call used the default `Symbol`, so the first leaf was constructed as
`Symbol('q0')`.

Expected behavior from public intent: the recursive call should use
`Function`, so the first leaf is constructed as `Function('q0')` and has
undefined-function type.

Classification: code bug.

Related proof obligations: PO1, PO2, PO3.

Resolution: V1 changed the recursive call to `symbols(name, cls=cls, **args)`.

## F2 - Confirmed Frame: Output Shape Is Preserved

Input:

```python
symbols(('q:2', 'u:2'), cls=Function)
```

Expected shape: outer tuple with separate `q` and `u` groups.

Source trace after V1: the iterable branch still appends one recursive result
per input element and returns `type(names)(result)`.

Classification: compatibility confirmation.

Related proof obligations: PO4, PO7.

Resolution: no additional source edit required.

## F3 - Confirmed Frame: Existing Keyword Arguments Are Preserved

Input family:

```python
symbols((name1, name2), cls=SomeClass, **args)
```

Expected behavior: existing assumptions and keyword arguments continue to reach
the string/range constructor path.

Source trace after V1: the recursive call still passes `**args`; it only adds
the missing `cls=cls`.

Classification: compatibility confirmation.

Related proof obligations: PO5, PO6, PO7.

Resolution: no additional source edit required.

## F4 - Honesty Finding: Proof Not Machine-Checked

The K artifacts and proof are constructed only. Per benchmark instructions, no
tests, Python, `kompile`, `kast`, or `kprove` were run.

Classification: proof limitation, not a production-code bug.

Related proof obligation: PO8.

Resolution: keep tests; do not claim machine-checked status.
