# Control notes — review outcome for sympy__sympy-18199

This round audited the V1 fix in `repo/sympy/ntheory/residue_ntheory.py`
(`nthroot_mod`) and either changed or confirmed it. Every decision below cites a
numbered entry in `review/FINDINGS.md`.

## Summary of the verdict

V1's behavioural fix — short-circuiting `nthroot_mod` to return `0` / `[0]` when
`a % p == 0` — is **correct, complete, and minimal**. The audit produced no
correctness, edge-case, error-handling, regression, or API-contract objection.
The only changes made are documentation/clarity improvements. No control flow or
returned value was altered.

## Decisions

### Kept unchanged: the core branch and its placement

The branch

```python
    if a % p == 0:
        return [0] if all_roots else 0
```

placed after the `isprime(p)` guard and before the two solving paths, stands
exactly as in V1. Justification, by finding:

- **Finding 1 / Finding 2** — For prime `p`, `x**n ≡ 0 (mod p)` ⟺ `x ≡ 0`, so
  `{0}` is the exact and *complete* root set. Returning `0`/`[0]` is right; there
  is no non-zero root to merge in, so the simple short-circuit is preferred over
  computing a general root set and appending `0`.
- **Finding 3** — Keeping the branch *after* `isprime(p)` is deliberate and must
  not change: composite `p` with `a ≡ 0` can have non-zero roots (e.g.
  `x**2 ≡ 0 (mod 4)` → `{0, 2}`), so the branch must stay behind the prime guard
  to avoid emitting a wrong `[0]`; composite `p` keeps raising
  `NotImplementedError`.
- **Finding 4** — Placing it *after* `is_nthpow_residue` is safe because that
  guard returns `True` for `a % m == 0` (`n ≥ 1`), so the `a ≡ 0` case is not
  prematurely turned into `None`.
- **Finding 5** — The short-circuit also avoids the latent `ValueError` from
  `discrete_log(p, 0, h)` inside `_nthroot_mod1`; relocating or removing the
  branch would re-expose that crash. Hence the position is load-bearing.
- **Finding 6** — `n == 2` is intentionally left to `sqrt_mod` (which already
  handles `a == 0`); no duplicate handling was added, and both paths agree on
  `0`/`[0]`.
- **Finding 7 / Finding 8** — Return types/values honour the documented
  contract and no new error path is introduced, so no defensive code was added.
- **Finding 9 / Finding 10** — No regression in the existing test loop (it never
  feeds `a ≡ 0`) and the `solveset` caller consumes `[0]` correctly, so no
  compatibility shim was needed.

Because findings 1–10 are all PASS, the logic is confirmed rather than rewritten.

### Change 1 — Added doctest examples (traces to Finding 11)

Added to the `nthroot_mod` docstring:

```
    >>> nthroot_mod(17*17, 5, 17)
    0
    >>> nthroot_mod(17*17, 5, 17, True)
    [0]
```

Rationale (Finding 11): the public docstring carried no example of the fixed
behaviour. These two lines are the issue's own scenario, document both the
`all_roots=False` (smallest root) and `all_roots=True` (full list) modes, match
the existing terse example style, and are self-verifying. The expected outputs
were derived by tracing the function: `289 % 17 == 0` ⇒ the new branch returns
`0` and `[0]` respectively (consistent with Finding 1). This adds documentation
only; it changes no logic.

### Change 2 — Reworded the inline comment (traces to Finding 11)

Changed the comment from phrasing about `x**n = 0` to phrasing about the actual
trigger condition:

```python
    if a % p == 0:
        # ``a`` is a multiple of the prime ``p``, so ``x = 0`` is the only
        # root of ``x**n = a (mod p)``
        return [0] if all_roots else 0
```

Rationale (Finding 11): the comment now explains *why* the branch fires
(`a` is a multiple of the prime `p`) and ties directly to the guarded condition,
improving readability. Cosmetic only; no behavioural effect.

## Net effect

- Logic: unchanged from V1 (confirmed correct by Findings 1–10).
- Docs/comments: improved (Finding 11).
- Risk: none identified; existing tests and the `solveset` caller are unaffected
  (Findings 9, 10).
