# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and the constructed proof obligations.

## F-001: Pre-V1 dtype predicate caused the reported bug

- Classification: code bug in the baseline implementation, resolved by V1.
- Evidence: `benchmark/PROBLEM.md` reports
  `(np.float16(1) * u.km).dtype -> dtype('float64')`.
- Mechanism: the original constructor predicate preserved a dtype only when
  `np.can_cast(np.float32, value.dtype)` was true, or when the dtype had
  fields. `float32` is not safely castable to `float16`, so `float16` fell into
  the default `astype(float)` path.
- Expected: `float16` should be preserved because it is a NumPy inexact dtype.
- Proof obligations: `PO-1`, `PO-2`, `PO-3`, `PO-4`.
- Status: resolved by the current `np.issubdtype(value.dtype, np.inexact)`
  predicate at both former `np.can_cast(np.float32, ...)` sites.

## F-002: The correct repair is the inexact dtype family, not a float16 special case

- Classification: spec adequacy finding.
- Evidence: the public hint says it is reasonable to allow every inexact type.
- Alternative considered: special-case only `np.float16`.
- Reason rejected: it would satisfy the single reproducer but leave the formal
  predicate tied to a legacy `float32` castability approximation instead of the
  public family obligation.
- Proof obligations: `PO-2`, `PO-4`.
- Status: V1 satisfies this by using `np.issubdtype(..., np.inexact)`.

## F-003: Existing non-inexact dtype behavior is a required frame condition

- Classification: compatibility / frame condition.
- Evidence: public tests and docstring state explicit dtype is honored,
  integers and bool default to float, `float32` is preserved, and Decimal object
  defaults to float unless `dtype=object` is explicit.
- Risk checked: replacing the predicate must not preserve integer, bool, or
  object dtype by default.
- Proof obligations: `PO-5`, `PO-6`, `PO-7`, `PO-8`.
- Status: V1 keeps this frame condition. `np.issubdtype(..., np.inexact)` is
  false for integer, bool, and object dtypes, so those paths still cast to
  float; explicit dtype and structured dtype behavior are unchanged.

## F-004: No public compatibility break from V1

- Classification: compatibility finding.
- Evidence: V1 changes no function signature, return class, or unit
  multiplication dispatch path.
- Proof obligations: `PO-1`, `PO-9`.
- Status: no source change beyond V1 is justified.

## F-005: Residual verification status

- Classification: proof status / test guidance.
- Evidence: benchmark constraints forbid running tests, Python, or K tooling.
- Status: proof is constructed, not machine-checked. Do not remove tests based
  on this proof unless the emitted `kompile`/`kprove` commands are later run
  and return `#Top`.

## Open Code Findings

None. The audit did not surface a source-level problem in V1 that requires a V2
code edit.
