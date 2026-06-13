# PROOF_OBLIGATIONS.md — pytest-dev/pytest#6197 (V1)

The obligations that must hold for the V1 fix to satisfy [`SPEC.md`](SPEC.md). Each is
labelled with its discharge tier and status. Discharge sketches are in
[`PROOF.md`](PROOF.md). **Constructed, not machine-checked.**

Notation: `mounted ∈ {0,1}` (import side effect on the `0→1` edge), `yielded` = nodes
produced, `i` = nodes processed, `N` = total nodes the package yields, `M,Y,I` symbolic.

---

## A. Behaviour-preservation obligations (V1 vs V0)

| # | Obligation | Tier | Status |
|---|---|---|---|
| **O-A1** | The multiset of nodes yielded by V1 equals that of V0. | structural / read-set argument | **discharged** — no collection statement reads `self._obj`/`self.own_markers` (checked: `visit`, `_recurse`, `_collectfile`, `parts`, `pkg_prefixes` use only `fspath`, `config`, `session`, hookproxy). Therefore moving/guarding the mount cannot change which nodes are produced. |
| **O-A2** | V1 yields nodes in the same order as V0. | structural | **discharged** — the init-module branch still precedes the loop; the loop order (`bf=True, sort=True`) and the `continue`/`pkg_prefixes` control flow are byte-for-byte unchanged; `for x in self._collectfile(path): … yield x` preserves the order of `yield from self._collectfile(path)`. |

## B. Safety obligation (the #6197 fix)

| # | Obligation | Tier | Status |
|---|---|---|---|
| **O-B1 (P1)** | `mounted ⇒ yielded ≥ 1` (no `__init__.py` import without a contributed node). Corollary: `N = 0 ⇒ ¬mounted`. | reachability `(COLLECT)` + arith | **constructed** — safety corollary of `(COLLECT)`; VCs linear (Z3). |
| **O-B2** | The mount is reachable *only* immediately before a `yield`. | syntactic (guardedness/ordering) | **discharged by inspection** — the *only* two textual occurrences of `self._mount_obj_if_needed()` are (i) line 652, immediately followed by `yield Module(init_module, self)` (line 653); (ii) line 674, immediately followed by `yield x` (line 675). No other call sites in `collect()`. |

## C. Marker-readiness obligations (keep `test_skip_package`)

| # | Obligation | Tier | Status |
|---|---|---|---|
| **O-C1 (P2)** | `yielded ≥ 1 ⇒ mounted`, and mount precedes the first `yield`. Corollary: `N ≥ 1 ⇒ mounted`. | reachability `(COLLECT)` + O-B2 | **constructed** — marker corollary of `(COLLECT)`; the *ordering* part is O-B2. |
| **O-C2** | Mounting populates `Package.own_markers` with `__init__.py`'s `pytestmark`. | semantic (unchanged helper) | **discharged** — `_mount_obj_if_needed()` runs `own_markers.extend(get_unpacked_marks(obj))` because `Package._ALLOW_MARKERS is True`; helper unchanged by V1. |
| **O-C3** | `own_markers` is ready before the skip check. | scheduling argument | **discharged** — all collection finishes before any `runtest`; the mount happens during collection (O-C1), the skip check runs at `runtest_setup`. |

## D. Loop / circularity obligations

| # | Obligation | Tier | Status |
|---|---|---|---|
| **O-D1** | `(LOOP)` circularity: from `(M,Y,I)`, `I ≤ N`, `M∈{0,1}`, the loop reaches `i=N`, `yielded=Y+(N−I)`, `mounted = M ∨ (I<N)`. | reachability + coinduction | **constructed** — guarded by the guard-eval step; body branch invokes `(LOOP)` at `(1, Y+1, I+1)`; exit branch `I=N`. |
| **O-D2 (SC1)** | `0 ≤ I ≤ N` on every reachable loop state. | linear (Z3) | **discharged** — entry `I=0≤N`; body step `I≤N ∧ I<N ⇒ I+1≤N`. |
| **O-D3 (SC2)** | `mounted ∈ {0,1}` preserved. | linear/boolean (Z3) | **discharged** — entry `0`; body sets `1`; both in `{0,1}`. |
| **O-D4** | Loop step VC: `yielded` closed form. `(Y+1)+(N−(I+1)) = Y+(N−I)`. | linear (Z3) | **discharged**. |
| **O-D5** | Loop step VC: `mounted` closed form. body-taken (`I<N`): `1 = M ∨ (I<N)` since RHS=1; exit (`I=N`): `M = M ∨ false`. | boolean (Z3) | **discharged**. |

## E. Composition obligation

| # | Obligation | Tier | Status |
|---|---|---|---|
| **O-E1** | `(COLLECT)` from the entry state: instantiate `(LOOP)` at `(M=0,Y=0,I=0)` ⇒ `yielded=N`, `mounted = 0 ∨ (0<N) = (N≥1)`. Account for the init-module branch as the (optional) first node folded into `N`. | Transitivity + Consequence | **constructed**. |

## F. Out-of-scope / residual obligations (explicitly NOT discharged)

| # | Obligation | Why out of scope |
|---|---|---|
| **O-F1** | **Termination** of `this_path.visit(...)` and the loop. | partial correctness by default; the file tree is finite in practice. Recommendation only (see ITERATION_GUIDANCE G3). |
| **O-F2** | Precise condition “import `__init__.py` **iff** a *descendant test* exists” (vs V1's sound over-approximation “yields ≥ 1 node”). | This is **finding F2**. Not an obligation V1 claims to meet; meeting it precisely needs lookahead/recursive parent-mount that would risk O-C1 (nested marker propagation). Deliberately left as a residual; routed to ITERATION_GUIDANCE G1. |
| **O-F3** | Functional correctness of `python_files` matching, dedup, `_recurse` ignores. | unchanged from V0; inherited, not re-proved. |

---

## Discharge summary

- **Discharged by inspection/structure:** O-A1, O-A2, O-B2, O-C2, O-C3, O-F (declared
  out of scope).
- **Constructed (symbolic execution + Z3-tier VCs), not machine-checked:** O-B1, O-C1,
  O-D1–O-D5, O-E1.
- **No nonlinear or `[simplification]`-tier VCs** arose — all arithmetic is linear and
  all logic is boolean, so the bundled Z3 tier suffices.
- **No obligation forced an undischargeable VC**, i.e. the audit found **no correctness
  bug** in V1. The only open item is the *intentional* residual O-F2 / F2.
