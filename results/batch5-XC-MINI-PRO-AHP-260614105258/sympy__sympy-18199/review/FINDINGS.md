# Code review — V1 fix for sympy__sympy-18199

Scope of the change under review (in `repo/sympy/ntheory/residue_ntheory.py`,
function `nthroot_mod`):

```python
    if not isprime(p):
        raise NotImplementedError("Not implemented for composite p")

    if a % p == 0:
        # ``x**n = 0 (mod p)`` has the single root ``x = 0`` for prime ``p``
        return [0] if all_roots else 0

    if (p - 1) % n == 0:
        return _nthroot_mod1(a, n, p, all_roots)
```

Each finding is numbered; the verdict (PASS / MINOR / FAIL) records whether it
requires a code change.

---

## 1. Correctness against the issue — PASS

The issue: for `x**n = a (mod p)` with `a % p == 0`, `x = 0` is a root that was
not returned. For a **prime** modulus `p`, `x**n ≡ 0 (mod p)` ⟺ `p | x**n` ⟺
`p | x` (since `p` is prime) ⟺ `x ≡ 0 (mod p)`. Hence the *complete* solution
set is exactly `{0}`. V1 returns `0` (smallest root) / `[0]` (all roots), which
is correct **and** complete. The issue's example `nthroot_mod(17*17, 5, 17)`
(a = 289 ≡ 0 mod 17) now returns `0`, and `nthroot_mod(17*17, 5, 17, True)`
returns `[0]`. Confirmed correct.

## 2. Completeness — is `[0]` ever a *partial* answer? — PASS

Skeptical check of whether `a ≡ 0 (mod p)` could coexist with a non-zero root.
A non-zero `x ∈ {1,…,p-1}` is a unit mod the prime `p`, so `x**n` is also a unit
and can never be `≡ 0`. Therefore no non-zero root exists, and returning only
`[0]` is exhaustive (not a partial list that ought to be merged with other
roots). No need to compute and append `0` to a general root set.

## 3. Placement relative to the `isprime(p)` guard — PASS (important)

The check sits **after** `if not isprime(p): raise NotImplementedError`. This is
essential: for *composite* `p`, `a ≡ 0 (mod p)` may have **non-zero** roots
(e.g. `x**2 ≡ 0 (mod 4)` has roots `{0, 2}`; `x**2 ≡ 0 (mod 9)` has `{0, 3, 6}`).
Returning `[0]` there would be wrong. By keeping the new branch behind the
prime guard, composite `p` still raises `NotImplementedError` exactly as before,
so V1 cannot emit a wrong answer for the unsupported composite case.

## 4. Placement relative to the `is_nthpow_residue` guard — PASS

`is_nthpow_residue(a, n, p)` returns `True` whenever `a % m == 0` for `n ≥ 1`
(residue_ntheory.py:641-642), so the earlier `if not is_nthpow_residue(...):
return None` does **not** swallow the `a ≡ 0` case — control correctly reaches
the new branch. (For `n == 0`, `is_nthpow_residue` returns `a == 1`, which is
`False` for any multiple of a prime `p`, so `nthroot_mod` returns `None`; that
is out of the documented contract `n : positive integer` and is harmless.)

## 5. Avoids the latent crash in the `_nthroot_mod1` path — PASS

Without V1, an input with `(p - 1) % n == 0` and `a ≡ 0` (e.g.
`nthroot_mod(11, 5, 11)`) would call `_nthroot_mod1`, which computes
`s1 = pow(s, f, p) = 0` and then `discrete_log(p, 0, h)`. A discrete log of `0`
does not exist and raises `ValueError`. V1 short-circuits before this path, so
the previously-crashing inputs now return the correct `0`/`[0]`. Confirmed
improvement, no new error path introduced.

## 6. `n == 2` consistency — PASS

`n == 2` returns earlier via `sqrt_mod(a, p, all_roots)` and never reaches the
new branch. For `a ≡ 0`, `sqrt_mod`→`sqrt_mod_iter` already handles `a == 0`
through `_sqrt_mod1`, yielding `0`/`[0]`. So the square-root case was already
correct and stays untouched; V1's `n != 2` handling produces the *same*
`0`/`[0]`, i.e. consistent behaviour across the two code paths. No redundant or
conflicting handling was added.

## 7. Return type / value contract — PASS

Docstring: "`all_roots`: if False returns the smallest root, else the list of
roots." For `a ≡ 0` the only root is `0`, which is also the smallest, so `0`
(scalar) and `[0]` (list) honour the contract. The values are plain Python
`int`s, matching the docstring examples (`8`, `23`, …) and the other return
paths (`min(res)` / sorted list of `pow(...)` ints). No `Integer`/`int`
mismatch introduced.

## 8. Error handling / input validation — PASS

`as_int` and the `is_nthpow_residue` guards (raising `ValueError` for `a < 0`
or `n < 0`) run before the new branch, so malformed inputs still raise as
before. `a % p` is computed only after `isprime(p)` guarantees `p ≥ 2`, so the
modulo is well defined (no division-by-zero / no negative modulus). The new
branch adds no exception-raising code of its own.

## 9. Regression risk in the existing test suite — PASS

The exhaustive loop in `tests/test_residue.py` iterates `for a in range(1, p-1)`,
which never includes a multiple of `p` (since `1 ≤ a ≤ p-2 < p`), and the
explicit `(a, q, p)` cases all have `a % p != 0`. Therefore the new branch is
never exercised by the existing assertions and cannot change their outcomes.
Notably, the loop's brute-force oracle `d[pow(i, q, p)]` for `i in range(p)`
would map `d[0] == [0]`, so extending it to `a == 0` would expect exactly `[0]`
— which is what V1 returns.

## 10. Interaction with the only non-test caller (`solveset`) — PASS

`solvers/solveset.py:1205` calls `nthroot_mod(rhs, expo, m, all_roots=True)`
and iterates the returned list, building `ImageSet(Lambda(n, m*n + rem), …)`.
V1's `[0]` yields `m*n + 0`, i.e. `x ≡ 0 (mod m)` — correct. Previously this
case could raise `ValueError` inside `_nthroot_mod1` (caught at solveset.py:1208)
and silently drop the solution, so V1 is also a behavioural improvement here.
`None` and exception handling in the caller are unaffected.

## 11. Style / documentation — MINOR (actionable)

- Style: the ternary early-return matches the nearby concise early returns
  (`return sqrt_mod(...)`, `return _nthroot_mod1(...)`); acceptable.
- Inline comment: accurate but phrased in terms of `x**n = 0` rather than the
  triggering condition `a % p == 0`; can be made slightly clearer.
- Documentation gap: the public docstring gained no example of the fixed
  behaviour. Adding a short doctest (the issue's own scenario) documents the
  change and is self-verifying. **This is the one improvement worth making.**

---

## Verdict

The V1 logic is **correct, complete, and minimal**; findings 1–10 confirm it
and require no code change. The only actionable item is finding 11
(documentation/clarity): add a doctest for the `a % p == 0` scenario and lightly
reword the inline comment. No change to control flow or returned values.
