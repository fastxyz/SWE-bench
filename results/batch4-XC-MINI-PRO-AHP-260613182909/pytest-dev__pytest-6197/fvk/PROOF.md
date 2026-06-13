# PROOF.md — constructed correctness proof for the V1 fix (#6197)

**Constructed, NOT machine-checked.** The K definition
([`package_collect.k`](package_collect.k)) and claims
([`package_collect-spec.k`](package_collect-spec.k)) are written to be
`kompile`/`kprove`-able, but the toolchain is **not run** in this environment. A `#Top`
from `kprove` is what would upgrade this from *constructed* to *machine-verified*.

Proves: the abstracted model of `Package.collect()` satisfies the safety + marker
contract `mounted ⟺ yielded ≥ 1` (with the mount ordered before the first yield). See
[`SPEC.md`](SPEC.md) for intent and [`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md) for the
obligation list discharged here.

---

## 0. Faithfulness of the abstraction (trusted base)

`Package.collect()` is a generator over a filesystem walk. The property under proof —
"is `__init__.py` imported?" — depends only on whether/when `_mount_obj_if_needed()` runs,
and that runs at exactly two textual sites, each *immediately before* a `yield`
(`PROOF_OBLIGATIONS` O-B2). Nothing in the collection control flow reads the mounted
object (O-A1). Therefore the side-effect behaviour of the real method is faithfully
captured by the counting loop in `package_collect.k`:

```
mounted = 0 ; yielded = 0 ; i = 0
while ( i < n ) { mounted = 1 ; yielded = yielded + 1 ; i = i + 1 }
```

with `n = N` = total nodes the method yields = `(init-module matched ? 1 : 0)` +
`Σ_path len(self._collectfile(path))`. Skip/`continue` branches and the
`pkg_prefixes.add` directory branch contribute `0` and are invisible. This collapse is
the *adequacy assumption* of the mini-X fragment (part of the trusted base).

> The nested per-path structure of the real code is what makes finding **F2** visible:
> `N` counts *yielded nodes*, and a yielded **nested `Package`** counts toward `N` even
> if that sub-package later collects nothing. The abstraction names this honestly — see
> §5 and FINDINGS F2.

## 1. Claims (from `package_collect-spec.k`)

- **(LOOP)** loop circularity, side condition `I ≤ N ∧ M∈{0,1}`:
  `⟨while…⟩, mounted↦(M⇒?Mf), yielded↦(Y⇒Y+(N−I)), i↦(I⇒N), n↦N`
  with `?Mf = 1 ⟺ (M=1 ∨ I<N)`.
- **(COLLECT)** function contract, precondition `N ≥ 0`:
  from `mounted↦0, yielded↦0, i↦0, n↦N` reach `yielded↦N`, `mounted↦?Mf` with
  `?Mf = 1 ⟺ N ≥ 1`.

## 2. Proof of (LOOP) — guarded coinduction

K adds every claim in the module as a coinduction hypothesis. We prove `(LOOP)` using
`(LOOP)` itself, legal only after ≥ 1 genuine `=>⁺` step (guardedness).

1. **Guard step (earns the hypothesis).** `while (i<n){…}` heats to evaluate `i < n`:
   look up `i ↦ I`, `n ↦ N` (Axiom + `seqstrict` heating), reduce to `I <Int N` (Axiom
   `<`). This is the genuine `=>⁺` step.
2. **Case split on the guard (`#Or`).**
   - **Body-taken branch (`I <Int N = true`).** Run the body:
     `mounted = 1 ;` → `<store> mounted ↦ (M ⇒ 1)`;
     `yielded = yielded + 1 ;` → look up `Y`, `Y +Int 1`, store `yielded ↦ Y+1`;
     `i = i + 1 ;` → `i ↦ I+1`.
     The `<k>` is back at `while (i<n){…}` in state `(mounted=1, yielded=Y+1, i=I+1)`.
     **Invoke the circularity** `(LOOP)` on this shifted state — its precondition
     `I+1 ≤ N` holds because `I < N` (O-D2), and `1 ∈ {0,1}` (O-D3). It yields:
     `yielded = (Y+1) + (N−(I+1)) = Y + (N−I)` ✓ (O-D4);
     `i = N` ✓;
     `mounted = 1 ∨ (I+1 < N) = 1`. Required `?Mf = (M=1 ∨ I<N)`; since `I<N` here, RHS
     `= 1` ✓ (O-D5).
   - **Exit branch (`I <Int N = false`, i.e. `I = N`).** `#branch(false,…) => .K`; the
     loop terminates with no further change: `yielded = Y = Y + (N−I)` (as `N−I = 0`) ✓;
     `i = I = N` ✓; `mounted = M`. Required `?Mf = (M=1 ∨ I<N) = (M=1 ∨ false) = M` ✓.
3. Both branches reach the claimed post-state ⇒ **(LOOP) proved** (constructed). The VCs
   (O-D2…O-D5) are linear arithmetic / boolean ⇒ Z3 (no `[simplification]` needed).

## 3. Proof of (COLLECT) — compose via the loop lemma

Start at `(mounted=0, yielded=0, i=0, n=N)`, `N ≥ 0`.

1. Instantiate **(LOOP)** as a lemma at `M=0, Y=0, I=0` (precondition `0 ≤ N` from
   `N ≥ 0`; `0 ∈ {0,1}`). By Transitivity reach:
   `yielded = 0 + (N − 0) = N` ✓;
   `i = N`;
   `mounted = (0=1 ∨ 0<N) = (N ≥ 1)`.
2. By Consequence, `?Mf = (N ≥ 1 ? 1 : 0)`, i.e. the `ensures`
   `(?Mf=1 ∧ N≥1) ∨ (?Mf=0 ∧ N=0)` holds (using `N ≥ 0`). ⇒ **(COLLECT) proved**
   (constructed).

## 4. Corollaries (the deliverables)

- **Safety (O-B1 / P1 / #6197 fix):** set `N = 0` in (COLLECT) ⇒ `mounted = 0`. With O-A1
  (`N = 0 ⟺ collect yields nothing`) and O-B2 (mount only just before a yield): **a
  package that contributes nothing never imports its `__init__.py`.** Concretely the
  `foobar/__init__.py: assert False` repro: `N = 0` ⇒ never imported ⇒ `1 passed`.
- **Markers (O-C1 / P2 / `test_skip_package`):** for `N ≥ 1`, `mounted = 1` and (O-B2,
  O-C3) the mount precedes the first yield and thus precedes any `runtest` skip check ⇒
  `Package.own_markers` carries `__init__.py`'s `pytestmark` in time ⇒ both package tests
  skipped.

## 5. Residual surfaced by the proof — F2

The contract is over `yielded ≥ 1`. The proof makes explicit that `N` (hence `yielded`)
counts **nested `Package` nodes** too. So for `pkg/` that yields only a nested
`Package(sub)` with no tests below it, `N ≥ 1` ⇒ `mounted = 1` ⇒ `pkg/__init__.py`
imported. This is **sound** (it never *misses* an import needed for nested marker
propagation) but **non-minimal**. It is *not* a violated obligation — see
PROOF_OBLIGATIONS O-F2 and FINDINGS F2; routed to ITERATION_GUIDANCE G1.

## 6. Test-redundancy report (benefit #1) — recommendation only

The proof is about a **side-effect invariant**, not a pure input→output function, so it
subsumes far fewer tests than an arithmetic contract would. **Conditioned on
machine-checking** (run `kprove` to `#Top` first), and assuming the abstraction adequacy:

- **Candidate-redundant (only after machine-check):** none of the visible tests assert
  *exactly* the proved invariant in isolation, so no outright removal is recommended.
  The closest, `test_collect_pkg_init_only` (a package whose `__init__.py` is/ isn't a
  test module under different `python_files`), is **partially** covered by `(COLLECT)`'s
  `N` accounting but also pins *which* nodes are produced (O-A1 territory), so **keep**.
- **Keep (out of scope of the proof):**
  - `test_skip_package` — exercises O-C1/O-C2/O-C3 *and* the real marker semantics the
    abstraction treats opaquely; keep as the guard against a regression to “delete the
    mount”.
  - `test_collect_init_tests`, `test_collect_pkg_init_and_file_in_args`,
    `Test_getinitialnodes.test_pkgfile`, `test_collectignore_via_conftest`,
    `test_collect_pyargs_with_testpaths` — these pin the **functional** postcondition
    (O-A1/O-A2) and the Session-level `_pkg_roots`/parent-walk wiring, which the
    side-effect abstraction does not cover. Keep.
  - Any **new** #6197 regression test (the `foobar/__init__.py` repro) — it directly
    checks the safety corollary; keep as the executable witness of F1’s fix.
  - **Termination/integration** tests — partial correctness says nothing about halting or
    cross-module wiring. Keep.
- **CI time saved:** ~0 (no removals recommended). The value here is benefit #2 (the
  Findings), not test pruning — appropriate for a side-effect bugfix.

## 7. Residual risk

- **Partial correctness only** — termination of `visit`/the loop is not proved (O-F1).
- **Trusted base:** (a) adequacy of the §0 abstraction (the counting-loop model of the
  generator's side effects); (b) the reachability proof-system metatheory + `kprove`;
  (c) the Z3 oracle for the linear/boolean VCs; (d) the helper `_mount_obj_if_needed()`
  and `fspath.pyimport` treated as opaque (mount = single guarded side effect).
- **Constructed, not machine-checked** — see commands below.

## 8. Reproduce the machine check

```sh
kompile fvk/package_collect.k --backend haskell        # compile the mini-Python fragment
kast    --backend haskell fvk/package_collect-spec.k   # (optional) confirm the claims parse
kprove  fvk/package_collect-spec.k                      # discharge (LOOP) and (COLLECT); expect #Top
```

Expected: `#Top` for both claims (all VCs are linear arithmetic / boolean; no
`[simplification]` lemmas required). Until then: **constructed, not machine-checked**;
keep the tests listed in §6.
