# Public Compatibility Audit

Changed public symbol: none.

Changed source location: internal implementation of `Mod.eval` in
`repo/sympy/core/mod.py`.

Compatibility result: pass. V1 does not change the `Mod` constructor signature,
method names, import paths, subclass dispatch calls, or producer/consumer data
shape. It only changes whether one internal simplification branch rewrites an
expression during construction.

Tests: no test files were modified, in accordance with the benchmark task.
