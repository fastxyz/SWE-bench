# FVK Findings

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## F-001: Escaped `PolynomialError` from Optional `Mod` Simplification

Classification: code bug, resolved by V1.

Input: a symbolic modulo expression whose dividend contains `Piecewise`, such as
the public example `(Piecewise((x, y > x), (y, True)) / z) % 1`, or the same path
reached through `exp(sinh(...)).subs({1: 1.0})`.

Observed before V1: `gcd(p, q)` inside `Mod.eval` raises `PolynomialError` with
the message that `Piecewise` generators do not make sense, and that exception
escapes.

Expected: the common-factor extraction is optional. If polynomial conversion
cannot handle the input, `Mod.eval` should skip that extraction and continue
with `G = 1`, preserving symbolic `Mod` behavior.

Evidence: E1, E2, E3, E5, E6. Obligations: PO-001, PO-004, PO-005.

V1 audit result: satisfied. The patched `try`/`except PolynomialError` surrounds
the `gcd` extraction and sets `G = S.One` on failure.

## F-002: Supported `gcd` Simplifications Must Not Regress

Classification: preservation obligation, satisfied by V1.

Input: symbolic modulo expressions whose `gcd(p, q)` succeeds and returns a
nontrivial factor.

Observed before V1: `Mod.eval` divides `p` and `q` by `G`, applies `gcd_terms`,
and continues with the simplified values.

Expected after V1: same behavior.

Evidence: E4, E5. Obligation: PO-002.

V1 audit result: satisfied. The successful path is still the original code
inside the `try` block.

## F-003: Branchwise `gcd(Piecewise(...), x)` Is Underspecified Here

Classification: underspecified intent, no V2 source change.

Input: direct polynomial `gcd` calls such as `gcd(Piecewise((x, x > 2), (2,
True)), x)`.

Observed: the public discussion notes the current behavior raises
`PolynomialError` and proposes a possible branchwise result.

Expected for this task: no committed branchwise `gcd` semantics. The discussion
explicitly calls the two-`Piecewise` case messier, and the mergeable repair is
localized to `Mod` not leaking an optional simplification failure.

Evidence: E8. Obligations: PO-001 and PO-005 cover `Mod`, not standalone `gcd`.

V1 audit result: no source change. Implementing branchwise `gcd` would be a
larger new polynomial feature and is not necessary to satisfy the reported
`subs`/`Mod` failure.

## F-004: Old Assumptions Cache Rollback Is a Broader Design Issue

Classification: underspecified intent / separate design issue, no V2 source
change.

Input: arbitrary old-assumption queries where an exception is raised after the
assumptions dict has been prefilled with `None`.

Observed: the issue discussion identifies nondeterminism from cached `None`
entries after exceptions.

Expected for this task: the reported expression should not raise the
`PolynomialError` that creates the stale-cache path. Removing the assumptions
prefill alone would make the failure deterministic rather than successful, and
the public discussion says that broader change leads to many `RecursionError`
examples.

Evidence: E9. Obligations: PO-001 and PO-005.

V1 audit result: no source change. The Mod-local fix removes the exception for
the reported path; global assumptions-cache semantics remain a separate design
question.

## F-005: FVK Proof Is Over a Mini-Semantics

Classification: proof capability boundary, not a code bug.

Input: the full SymPy object model, assumption engine, and polynomial conversion
machinery.

Observed: the bundled FVK fast path cannot faithfully model the entire dynamic
Python/SymPy runtime.

Expected: use a property-complete mini-semantics that preserves the decisive
axis: whether `PolynomialError` from optional `gcd` extraction escapes or falls
back to symbolic `Mod` construction.

Evidence: FVK methodology. Obligations: PO-007.

V1 audit result: acceptable for this audit. The proof is constructed, not
machine-checked, and the artifact labels preserve that limitation.

