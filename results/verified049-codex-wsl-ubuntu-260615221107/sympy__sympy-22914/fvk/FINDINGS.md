# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent and source inspection only.

## F-001: Pre-fix unsupported fallback for `Min` and `Max` - resolved by V1

- Input: `pycode(Min(a, b))` and by symmetry `pycode(Max(a, b))`.
- Observed before V1: `Min` and `Max` were absent from `_known_functions`, so no generated `_print_Min` or `_print_Max` method existed and the generic code-printer fallback could record the expression as unsupported.
- Expected: `Min` prints as `min(a, b)` and `Max` prints as `max(a, b)` without a "Not supported in Python" comment.
- Evidence: I-001 through I-005 in `fvk/SPEC.md`.
- Status: Resolved by V1 because `_known_functions` now contains both `Max: max` and `Min: min`.

## F-002: Machine proof and tests were intentionally not run

- Input: the constructed K claims in `fvk/pycode-printer-spec.k`.
- Observed: no `kompile`, `kast`, `kprove`, Python, or test command was executed because the benchmark forbids execution.
- Expected: artifacts contain the commands and expected outcome for later machine checking.
- Classification: proof capability / environment boundary, not a code bug.
- Status: Open operational caveat. The proof is constructed, not machine-checked.

## F-003: Shared `_known_functions` also gives `MpmathPrinter` `Min` and `Max` support

- Input: `MpmathPrinter().doprint(Min(x, y))` and `MpmathPrinter().doprint(Max(x, y))`.
- Observed from source: `MpmathPrinter._kf` is built from `_known_functions`, so V1 causes the mpmath printer to emit `min(...)` and `max(...)` as well.
- Expected: no public API break; scalar mpmath code can use Python builtins for variadic min/max, and user overrides still win through `user_functions`.
- Classification: compatibility audit item.
- Status: Accepted; no source change recommended.

## F-004: Existing public tests do not cover plain `pycode` `Min`/`Max`

- Input: in-repo `repo/sympy/printing/tests/test_pycode.py`.
- Observed from source inspection: existing `Min`/`Max` coverage in that file targets NumPy lambdify behavior, not plain `PythonCodePrinter` or `pycode`.
- Expected: a focused regression test would assert `pycode(Min(x, y)) == "min(x, y)"` and `pycode(Max(x, y)) == "max(x, y)"`.
- Classification: test gap.
- Status: No test files modified, per benchmark instructions.
