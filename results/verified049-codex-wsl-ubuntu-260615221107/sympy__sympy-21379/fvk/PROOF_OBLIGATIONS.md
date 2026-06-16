# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## PO-001: Polynomial `gcd` Failure Is Contained

Statement: If `Mod.eval` reaches the common-factor extraction block with
nonzero divisor inputs and `gcd(p, q)` raises `PolynomialError`, then
`Mod.eval` must not propagate that `PolynomialError`; it must continue with
`G = S.One`.

Public evidence: E1, E2, E3, E5, E6.

Formal claim: `MOD-GCD-POLYERR` in `fvk/mod-spec.k`.

Status: discharged by source inspection of V1 and constructed proof.

## PO-002: Successful `gcd` Simplification Is Preserved

Statement: If `gcd(p, q)` succeeds, V1 must use the same simplification behavior
as the original implementation: when `G != 1`, divide by `G`, apply
`gcd_terms`, and continue.

Public evidence: E4, E5.

Formal claim: `MOD-GCD-OK` in `fvk/mod-spec.k`.

Status: discharged by source inspection. The original successful branch remains
inside the `try` block.

## PO-003: Legitimate Non-Scoped Errors Are Preserved

Statement: The fix must not catch or change modulo-by-zero behavior or earlier
direct-evaluation behavior. In particular, `q.is_zero` still raises
`ZeroDivisionError` before reaching the `gcd` fallback.

Public evidence: E7 and the `Mod` docstring's Python modulo convention.

Formal claim: `MOD-ZERO-DIVISOR` in `fvk/mod-spec.k`.

Status: discharged by source inspection and constructed proof.

## PO-004: Failed Extraction Does Not Partially Mutate `p` or `q`

Statement: On `PolynomialError` from the extraction block, the values used after
the block are the incoming `p` and `q`, with only `G` reset to `S.One`.

Public evidence: E3, E5, E6.

Formal claim: `MOD-GCD-POLYERR` in `fvk/mod-spec.k`.

Status: discharged. In Python, the tuple assignment to `p, q` occurs only after
the right-hand list comprehension completes. If `gcd` or `gcd_terms` raises,
control transfers to `except PolynomialError` before assignment, and V1 assigns
only `G = S.One`.

## PO-005: Reported `subs` Path Reaches the Repaired Edge

Statement: The public `subs` failure path enters `sinh._eval_is_real`, evaluates
`im % pi`, constructs `Mod`, and reaches the optional `gcd` extraction that can
raise on `Piecewise` generators.

Public evidence: E1, E2, E6.

Formal claim: represented by the `gcdPolynomialError` input to
`MOD-GCD-POLYERR`.

Status: discharged by the public traceback and source inspection.

## PO-006: Public Compatibility Is Preserved

Statement: V1 must not alter the public signature, dispatch shape, or return
protocol of `Mod`.

Public evidence: existing `Mod` class API and unchanged source signature.

Formal artifact: `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Status: discharged by source inspection.

## PO-007: FVK Adequacy Artifacts Are Present and Honest

Statement: The proof package must include intent, evidence, formal-English,
spec-audit, compatibility, K semantics, K claims, and a constructed proof, all
labeled as not machine-checked.

Public evidence: FVK method docs.

Formal artifacts: all files under `fvk/`.

Status: discharged for this audit package.

