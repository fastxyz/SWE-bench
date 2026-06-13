# PROOF.md — constructed correctness proof, django__django-15957

**Status: constructed, NOT machine-checked.** The MVP builds the proof and emits the
`kompile`/`kprove` commands but does not run the toolchain. The Findings (`FINDINGS.md`)
do not depend on machine-checking.

Artifacts: `fvk/mini-orm.k` (fragment semantics), `fvk/mini-orm-spec.k` (claims
`(WSLICE)`, `(WLOOP)`).

---

## 1. What is proved

**`(WSLICE)` — the off-by-one contract.** For every `m ≥ 0` and `0 ≤ low ≤ high`,

```
count_window_slice(m, low, high)  =  max(0, min(m, high) − low)  =  len(rows[low:high]).
```

`count_window_slice` is the mini-ORM encoding of the predicate V1 emits
(`RowNumber() > low AND RowNumber() <= high` over one partition of `m` rows). So the
window predicate keeps **exactly** the rows, at exactly the positions, that Python
slicing `rows[low:high]` keeps. This is the proof that V1 has **no off-by-one** and
faithfully implements per-partition slicing (PO1; `high=None` is PO2 with `high ≥ m`;
chained slices are PO3, composed earlier by `set_limits`).

**`(WLOOP)` — the loop circularity** that discharges `(WSLICE)`'s `while`.

---

## 2. The loop circularity `(WLOOP)` — proof by guarded coinduction

Invariant closed form `cf(K) = max(0, min(M,High) − max(K−1, Low))` = number of indices
`j ∈ [K, M]` with `Low < j ≤ High`. Claim: from `c=C, k=K` (side condition
`1 ≤ K ≤ M+1`, `0 ≤ Low ≤ High`, `0 ≤ M`) the loop reaches `c = C + cf(K)`, `k = M+1`.

Drive `<k>` by the `mini-orm.k` rules; the guard evaluation `k <= m` is the **genuine
`=>⁺` step** that earns the coinduction hypothesis (guardedness), then case-split (`#Or`)
on the guard:

- **Exit branch `K > M`** (so `K = M+1` by the side condition): guard `false`, loop ends
  with `k = M+1`, `c = C`. Need `cf(M+1) = 0`: `max(0, min(M,High) − max(M, Low))`. Since
  `Low ≤ M`? not necessarily — but `max(M,Low) ≥ M ≥ min(M,High)`, so the inner term
  `≤ 0`, hence `cf(M+1) = 0`. ✓ (Z3: linear, `min/max` expanded by case.)

- **Body branch `K ≤ M`**: run the `if (k>low) and (k<=high)` then `c += 1`/skip, then
  `k += 1`, reaching the same loop at `{c := C + δ, k := K+1}` with
  `δ = 1` if `Low < K ≤ High` else `0`. **Invoke the circularity** on that shifted state
  (its side condition `1 ≤ K+1 ≤ M+1` holds since `K ≤ M`): it contributes
  `(C + δ) + cf(K+1)`. Discharge the **step VC**

  ```
  δ + cf(K+1) = cf(K),    i.e.   [Low<K≤High] + max(0, min(M,High) − max(K, Low))
                                              = max(0, min(M,High) − max(K−1, Low)).
  ```

  Case-split on `K`'s position relative to `(Low, High]` and to `min(M,High)`; each case
  is linear and closes under Z3 (no nonlinear/divide-by-even VC arises — unlike `sum`,
  the accumulator is a *count*, not a quadratic). E.g. for `Low < K ≤ min(M,High)`:
  `max(K−1,Low)=K−1`, `max(K,Low)=K`, both inner terms positive, LHS
  `= 1 + (min(M,High) − K) = min(M,High) − (K−1)` = RHS. ✓

Both branches land on `c = C + cf(K)`, `k = M+1`. `(WLOOP)` holds.

## 3. The function contract `(WSLICE)` by Transitivity

`def count_window_slice…` files the function (`<funcs>`); `call` binds `m,low,high :=
M,LOW,HIGH` in a fresh `<store>`; the body inits `c=0, k=1`; the `while` is discharged by
**`(WLOOP)` used as a lemma** instantiated at its entry `{C:=0, K:=1}` (precondition
`1 ≤ 1 ≤ M+1` ✓). It contributes `c = 0 + cf(1) = max(0, min(M,High) − max(0,Low)) =
max(0, min(M,High) − LOW)` (since `LOW ≥ 0`). `return c` pops the frame and delivers that
value. The post-store implication `STORE[c<-V] #Equals STORE[c<-V']` collapses to
`V #Equals V'` via the map-extensionality `[simplification]`. Result:

```
A ⊢ (WSLICE):  count_window_slice(M,LOW,HIGH) ⇒ max(0, min(M,HIGH) − LOW)
               requires M≥0 ∧ 0≤LOW≤HIGH.
```

and `max(0, min(M,HIGH) − LOW) = len(rows[LOW:HIGH])` is the slice-length identity (Z3,
linear once `min/max` are case-expanded). **PO1/PO2/PO3 discharged.**

## 4. The control-flow obligations PO6/PO7 (no K needed — direct trace)

These are about *reachability of code*, discharged by reading the call graph, not by the
arithmetic semantics:

- **PO7 (containment).** Whole-repo `grep "_defer_next_filter = True"` ⇒ exactly two sites,
  both `_apply_rel_filters`. So `… and not self._defer_next_filter` alters
  `_filter_or_exclude` behaviour only for those internal callers; user-facing eager
  filters keep the original `TypeError`. The existing tests pin both sides
  (`test_slicing_cannot_filter_queryset_once_sliced` still raises;
  `test_filter_deferred` is non-sliced, unaffected).
- **PO6 (never executed).** no-`to_attr` path: `_apply_rel_filters` stashes the filter
  (`_deferred_filter`) on a sliced query → `prefetch_one_level` sets
  `qs._result_cache = vals` → `_fetch_all` short-circuits on non-`None` cache. The
  deferred filter is never compiled. So relaxing the guard cannot emit a wrong query. ∎

## 5. Trusted base (residual risk — argued, not re-proved)

This fix *composes* pre-existing, separately-tested Django machinery; those pieces are the
trusted base, exactly as the kit's mini-X fragment adequacy is trusted:

- **PO4 — partition/join reuse:** F-expression resolution + join reuse within one
  `add_q`, plus m2m `_next_is_sticky()`. Argued in PROOF_OBLIGATIONS PO4; not re-proved.
- **PO5 — QUALIFY × extra-select:** the window-filtering compiler path
  (`split_having_qualify` / `get_qualify_sql`). Spot-checked that extra-select aliases
  survive `with_col_aliases` (`compiler.py:310`), but the rewrite itself is trusted.
- **The semantics fragment.** `mini-orm.k` models the *arithmetic* of the rewrite, not SQL
  execution, ordering stability, or the ORM. Adequacy of that abstraction is trusted.
- **Partial correctness.** Termination/performance of the emitted SQL is the database's;
  not modelled.
- **Constructed, not machine-checked.** `#Top` from `kprove` would upgrade this.

## 6. Reproduce the machine check

```sh
kompile fvk/mini-orm.k --backend haskell          # compile the fragment semantics
kast    --backend haskell fvk/mini-orm-spec.k     # (optional) confirm the claims parse
kprove  fvk/mini-orm-spec.k                        # discharge (WSLICE),(WLOOP); expect #Top
```

Expected: `#Top` (all claims proved). Until then, the result is **constructed, not
machine-checked**, and any test-redundancy advice below stays conditioned on that run.

## 7. Test-redundancy (benefit 1) — recommendation only, conditioned on the machine check

- The hidden suite is not visible and must not be modified, so this is **advisory only**.
- Once `(WSLICE)` is machine-checked, unit assertions that merely pin a single in-domain
  `(low, high, m)` → slice-length/identity point (e.g. "`qs[:3]` prefetch yields 3 per
  parent", "`qs[1:3]` yields the 2 middle ones") are **subsumed** by the closed form and
  could be thinned. **Keep**, regardless: the `NotSupportedError` backend test (Finding 5,
  out of the proof's arithmetic domain), the no-`to_attr` / further-`.filter()` behaviour
  (Finding 2), unordered-determinism docs tests (Finding 3), the eager slice-guard test,
  and all integration tests exercising PO4/PO5 (join reuse, m2m extra-select) — the proof
  covers the index arithmetic, not the SQL wiring. **Net: keep essentially all tests** for
  this MVP; the arithmetic proof is confidence, not a license to delete ORM/integration
  tests.
