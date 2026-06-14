# Baseline notes — sympy__sympy-18199

## Issue

`nthroot_mod(a, n, p)` solves `x**n = a (mod p)`. When `a % p == 0`, the value
`x = 0` is a root (`0**n = 0 ≡ a (mod p)`), and for a **prime** `p` it is in fact
the *only* root. `nthroot_mod` failed to return this root.

Example from the issue: `nthroot_mod(17*17, 5, 17)` should report `0` as a root,
because `289 % 17 == 0`.

## Root cause

In `repo/sympy/ntheory/residue_ntheory.py`, `nthroot_mod` (and its helpers) never
special‑cases the situation `a ≡ 0 (mod p)`:

1. `is_nthpow_residue(a, n, p)` *does* return `True` for this case
   (`if a % m == 0: return True`, line 641‑642), so `nthroot_mod` does **not**
   short‑circuit to `None`.
2. After confirming `p` is prime, control falls into one of two solving paths,
   neither of which can produce the root `0`:
   - **`_nthroot_mod1` path** (`(p - 1) % n == 0`): it computes
     `s1 = pow(s, f, p)`, which is `0` when `s = a ≡ 0`, and then calls
     `discrete_log(p, 0, h)`. `0` is not in the multiplicative group, so the
     discrete log does not exist and this **raises `ValueError`** rather than
     returning `0`.
   - **gcd path** (the Euclidean‑on‑exponents algorithm): it only finds roots of
     `gcd(x**n - a, x**(p - 1) - 1)`. But `x = 0` is never a root of
     `x**(p - 1) - 1` (`0**(p-1) = 0 ≠ 1`), so the root `0` is structurally
     outside the set this algorithm searches. (For some inputs the degenerate
     arithmetic happens to yield `0`, but this is incidental and not reliable.)

For a prime modulus `p`, `x**n ≡ 0 (mod p)` ⟺ `p | x**n` ⟺ `p | x` ⟺ `x ≡ 0`,
so the complete and exact solution set in this case is exactly `{0}`.

## Change made

File: `repo/sympy/ntheory/residue_ntheory.py`, function `nthroot_mod`.

Inserted an explicit early return for `a % p == 0`, placed **after** the
`is_nthpow_residue`/`isprime` checks and **before** the two solving paths:

```python
    if not isprime(p):
        raise NotImplementedError("Not implemented for composite p")

    if a % p == 0:
        # ``x**n = 0 (mod p)`` has the single root ``x = 0`` for prime ``p``
        return [0] if all_roots else 0

    if (p - 1) % n == 0:
        return _nthroot_mod1(a, n, p, all_roots)
```

Why this placement:
- It is **after** `isprime(p)`, so composite `p` continues to raise
  `NotImplementedError` exactly as before (no behaviour change for the
  unsupported composite case).
- It is **after** the `n == 2` early return, which delegates to `sqrt_mod`.
  `sqrt_mod`/`sqrt_mod_iter` already handle `a == 0` correctly (via
  `_sqrt_mod1`), so the square‑root case is left untouched and keeps using its
  well‑tested path.
- It is **before** `_nthroot_mod1` and the gcd path, so the `ValueError`/missed
  root described above can never be reached for `a ≡ 0`.

Return type matches the rest of the function: a bare `int` `0` when
`all_roots=False`, and a list `[0]` when `all_roots=True` (consistent with the
sorted lists returned by the other branches).

## Impact / regression check

- Existing tests in `repo/sympy/ntheory/tests/test_residue.py` are unaffected:
  the exhaustive loop uses `for a in range(1, p - 1)` (never `a ≡ 0 mod p`), and
  the explicit `(a, q, p)` cases all have `a % p != 0`.
- The other caller, `repo/sympy/solvers/solveset.py:1205`
  (`nthroot_mod(rhs, expo, m, all_roots=True)`), iterates over the returned list.
  `[0]` is a valid list and yields `ImageSet(Lambda(n, m*n + 0), S.Integers)`,
  i.e. `x ≡ 0 (mod m)` — the correct answer. Previously this case could raise
  `ValueError` inside `_nthroot_mod1` (caught at solveset.py:1208), silently
  dropping the solution; the fix is therefore also an improvement there.

## Alternatives considered and rejected

- **Compute the normal roots and append `0`.** Rejected: for prime `p` there are
  no non‑zero roots when `a ≡ 0`, and the normal computation can either crash
  (`_nthroot_mod1`) or, in the gcd path, accidentally emit `0` already — appending
  would risk duplicates/crashes. A clean short‑circuit is simpler and exactly
  correct.
- **Fix `_nthroot_mod1` to detect `s ≡ 0` internally.** Rejected as broader and
  redundant: the gcd path would still need its own handling, so the single guard
  in `nthroot_mod` is the minimal, central fix that covers every path.
- **Place the check before `isprime(p)` (or at the very top).** Rejected to avoid
  changing the existing behaviour for composite `p` (which must still raise
  `NotImplementedError`) and to keep the `n == 2` case flowing through `sqrt_mod`.
- **Make `is_nthpow_residue` / the docstring carry the change.** Rejected:
  `is_nthpow_residue` is already correct (the residue *exists*); the bug is purely
  that `nthroot_mod` did not emit the corresponding root.
