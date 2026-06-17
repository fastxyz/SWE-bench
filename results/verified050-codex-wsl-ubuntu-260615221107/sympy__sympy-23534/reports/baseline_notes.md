# Baseline Notes

## Root Cause

`symbols()` accepts a keyword-only `cls` argument that controls which
symbol-like object constructor is used. The string-handling branch uses that
`cls` directly, so calls like `symbols('q:2', cls=Function)` create undefined
functions as expected.

When `names` is an iterable, `symbols()` recursively processes each entry with
`symbols(name, **args)`. Since `cls` is keyword-only and is not stored in
`args`, the recursive call falls back to the default `Symbol` constructor. That
is why `symbols(('q:2', 'u:2'), cls=Function)` returns tuples containing
`Symbol` instances instead of undefined functions.

## Files Changed

`repo/sympy/core/symbol.py`

The iterable branch now forwards the active `cls` value into recursive
`symbols()` calls with `symbols(name, cls=cls, **args)`. This preserves the
existing output container behavior while making nested string/range inputs use
the caller-provided symbol-like class.

`reports/baseline_notes.md`

This report records the root cause, the changed files, and the assumptions made
for the benchmark task.

## Assumptions

The intended behavior is that every input shape accepted by `symbols()` should
respect `cls`, including iterable containers that contain range strings.

The fix should be limited to propagating `cls` through the existing recursive
path. Other keyword arguments are already propagated through `args`, so no
larger refactor is needed.

No tests or project code were run, per the benchmark instructions.

## Alternatives Considered

One alternative was to special-case `Function` in the iterable branch. I
rejected that because the documentation describes `cls` as a general mechanism
for creating symbol-like objects, including `Wild`, `Dummy`, and other classes.

Another alternative was to restructure `symbols()` so `cls` is merged into
`args`. I rejected that because `cls` is intentionally keyword-only and the
minimal behavioral issue is the missing recursive argument, not the public
signature or argument handling model.
