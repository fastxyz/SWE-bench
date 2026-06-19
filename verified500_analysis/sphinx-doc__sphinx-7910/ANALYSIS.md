# sphinx-doc__sphinx-7910 — FVK analysis

- **Verdict:** C_ROBUSTNESS (low value) — fvk adds two defensive owner-resolution paths on top of a baseline that is already correct for the reported bug and all tests; only one adds genuinely new behavior, targeting a niche case the human gold fix never bothered with.
- **Pitch-worthiness (1-5):** 2

## Summary
The issue: `@functools.wraps`-decorated methods were not documented because owner-class resolution failed. Baseline fixes it by using module+qualname resolution (which `functools.wraps` makes work since it preserves `__module__`/`__qualname__`); passes all tests.

fvk adds (1) an `obj.__globals__` fallback and (2) an `unwrap(cls)` candidate. The `__globals__` fallback is near-dead code that restores brittleness baseline deliberately removed; the `unwrap(cls)` check is a real but niche extension (documenting members of decorated *classes* via `__wrapped__`).

## Verification
On the actual test and realistic inputs, baseline and fvk behave identically. fvk differs only on contrived cases (hand-crafted wrappers with bogus `__module__`; decorated classes). Gold uses a *different* mechanism again (`unwrap(obj).__globals__`) and does not add fvk's `unwrap(cls)` candidate.

**GOLD_MATCH: no.** Defensive hardening for niche/contrived cases that diverge from the oracle's approach — not a fix to a real baseline defect. CONFIDENCE: high.
