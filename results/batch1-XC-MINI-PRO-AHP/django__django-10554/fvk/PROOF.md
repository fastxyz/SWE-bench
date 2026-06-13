# PROOF — `Query.clone()` isolates combined queries (django__django-10554)

> **Constructed, NOT machine-checked.** The MVP builds the proof and emits the
> `kompile`/`kprove` commands but does not run them. Claims:
> [`query_clone-spec.k`](query_clone-spec.k); semantics: [`query_clone.k`](query_clone.k).

## 1. What is proved (plain language)

> For every set-operation query `q` whose combined-query graph is finite and acyclic,
> `c = clone(q)` produces an object graph that shares **no object** with `q`'s. Hence any
> in-place column reset (`set_values()`, run while compiling `c` or anything derived from
> it) leaves **every** query reachable from `q` unchanged, so a later re-evaluation of `q`
> still selects its full column list and its combinator `ORDER BY <position>` stays in
> range.

Two claims (`query_clone-spec.k`):

- **(CLONE-REC)** the recursion contract: `clone(R)` ⇒ fresh `?R`, with
  `reach(?R) ∩ reach(R) = ∅` and every cloned id `≥ N0`.
- **(CLONE-ISO)** the user-facing non-interference: after `c = clone(q)`,
  `setvals(M,V)` for `M ∈ reach(c)` preserves `colsOf` across `reach(q)`.

## 2. Proof of CLONE-REC — structural induction = the recursion circularity

`clone` is recursive, so (per `reachability-and-circularities.md` §3, the `(REC)` recipe)
its **own contract is the coinductive hypothesis**; guardedness is paid by the genuine
`clone(...)` reduction step before the hypothesis is reused. We induct on the (finite,
by SC-1) combined-query graph rooted at `R`.

Let `OBJS` be the heap, `R ∈ keys(OBJS)`, `obj(COLS, COMB) = OBJS[R]`, and assume every id
in `reach(OBJS,R)` is `< N0` (allocator high-water mark).

Symbolic execution of `clone(R)` (semantics in `query_clone.k`):

```
clone(R)
  →[axiom: clone]      cloneObj(R, COLS, COMB)
  →[axiom: cloneObj]   allocClone(COLS, cloneList(COMB))
  →* (evaluate cloneList(COMB))    -- see step (a)
  →[axiom: allocClone] N    with  <objs> := OBJS' [ N <- obj(COLS, COMB') ],
                                   <next> := N+1,  requires N ∉ keys(OBJS')
```

**(a) The list recursion `cloneList(COMB)`.** Case-split on `COMB` (`#Or`):

- **Base, `COMB = .List`** (R is a *leaf* — no operands; e.g. a plain `filter()` operand):
  `cloneList(.List) → .List`. Then `allocClone(COLS, .List)` allocates a fresh
  `N = ?R ≥ N0` (since all existing ids are `< N0`). `reach(OBJS', ?R) = {?R}`.
  Because `?R ≥ N0 >` every id in `reach(OBJS,R)`, we get `{?R} ∩ reach(OBJS,R) = ∅`. ✔

- **Step, `COMB = ListItem(C) REST`:**
  ```
  cloneList(ListItem(C) REST) → appendClone(clone(C), cloneList(REST))
  ```
  `clone(C)` is a **genuine `=>⁺` step** ⇒ guardedness satisfied ⇒ we may invoke the
  **CLONE-REC hypothesis on C** (its precondition re-checked: `C ∈ keys(OBJS)`,
  `acyclic(OBJS,C)` since a subgraph of an acyclic graph is acyclic, `reach(C) ⊆ reach(R)`
  all `< N0`). The hypothesis yields a fresh `?C` with `reach(?C) ∩ reach(C) = ∅` and all
  of `reach(?C) ≥ N0`. Apply the hypothesis again to `cloneList(REST)` (Transitivity); each
  recursive clone draws *strictly fresh* ids from the monotonically increasing `<next>`, so
  the per-operand cloned graphs are pairwise disjoint **and** disjoint from the
  yet-to-be-allocated root. Finally `allocClone` picks `?R ≥` the (now advanced) `<next> ≥
  N0`, fresh from everything.

  Compose: `reach(OBJS', ?R) = {?R} ∪ ⋃_i reach(?C_i)`. Every member is `≥ N0`; every
  member of `reach(OBJS,R) = {R} ∪ ⋃_i reach(C_i)` is `< N0`. Therefore
  `reach(OBJS', ?R) ∩ reach(OBJS, R) = ∅`. ∎(CLONE-REC)

The arithmetic side conditions are the **Z3 tier**: `N0 ≤ x` (fresh) and `y < N0`
(pre-existing) ⇒ `x ≠ y` ⇒ the two id-sets are disjoint. The only step the **bundled
`[simplification]` tier cannot close by itself** is folding those per-element `≠` facts
into the *set* equation `reach(?R) ∩ reach(R) = .Set`, because `reach` is an inductively
defined set — this is the **`[ESCALATION BOUNDARY]`** (PO-8 / VC-disjoint), routed to
separation logic + matching-μ-logic, **not** admitted as `[trusted]`.

## 3. Proof of CLONE-ISO — non-interference, by framing

From `c = clone(q)` (CLONE-REC) we have `reach(c) ∩ reach(q) = ∅`. Execute
`setvals(M, V)` with `M ∈ reach(c)`:

```
setvals(M, V)  →[axiom: setvals]  M   with  <objs> := OBJS[ M <- obj(V, COMB_M) ]
```

The rule rewrites **only** the single binding `M |-> …`. Take any `id ∈ reach(q)`. By
disjointness `id ≠ M`, so the map update leaves `OBJS[id]` untouched (map non-aliasing,
VC-frame). Hence `colsOf(id)` is preserved for every `id ∈ reach(q)`:
`preservedOn(reach(q), OBJS_before, OBJS_after) = true`. ∎(CLONE-ISO)

**Why this is exactly the bug fix.** Map "compile a `values_list()` derived from a union"
to `setvals(M, pk)` on the derivative's combined query `M`; map "re-evaluate the original
union" to reading `colsOf` over `reach(q)`. CLONE-ISO says the read sees the **full**
columns, so the outer `ORDER BY <position>` is in range — no
`ORDER BY position N is not in select list`.

## 4. Independence from `compiler.py:429` (PO-10)

The audited tree's `get_combinator_sql` clones each operand before `set_values`
(compiler.py:429). The CLONE-ISO proof **does not use** that fact: it only needs that the
*derived queryset's* operands are disjoint from the *original's*, which holds because the
derivation itself went through `clone()` (V1). Formally, model the two `get_combinator_sql`
variants as

- **(v429)** `setvals(clone(M), pk)` — mutate a fresh clone of the operand, or
- **(v0)** `setvals(M, pk)` — mutate the operand in place.

Under **(v0)**, `M` is the *derivative's* operand, and `M ∈ reach(c)` with
`reach(c) ∩ reach(q) = ∅`; CLONE-ISO §3 applies unchanged ⇒ `q` preserved. Under **(v429)**
`clone(M) ∈ reach(c)` likewise (CLONE-REC keeps it within the fresh region) ⇒ also
preserved. So V1 fixes #10554 **regardless** of whether `get_combinator_sql` clones at the
mutation site — V1 is correct as the decisive fix (if `:429` is absent from the true base)
and as defense-in-depth (if `:429` is present). See FINDINGS F7.

## 5. Test-redundancy (benefit 1) — conditioned on machine-checking

- **Keep, do not drop.** Every combinator test in `tests/queries/test_qs_combinators.py`
  exercises **SQL generation / DB round-trips** (`test_ordering`, `test_union_with_values`,
  `test_order_raises_on_non_selected_column`, …). The proof above is about **object-graph
  isolation**, a *different* property; it does **not** subsume any of those input/output or
  integration assertions. → **Keep all.**
- **Keep (out of domain / the bug's home).** Any new #10554 regression test ("re-evaluate a
  union after deriving a `values_list`") pins the *integration* behavior the proof argues
  for but does not, by itself, machine-check (no `kprove` run; heap-disjointness at the
  escalation boundary). → **Keep.**
- **CI time saved:** **0** — this proof recommends **no** removals. Object-aliasing
  correctness and SQL correctness are orthogonal here.

## 6. Reproduce the machine check (constructed, not run)

```sh
kompile fvk/query_clone.k --backend haskell           # compile the fragment
kast    --backend haskell fvk/query_clone-spec.k       # (optional) parse check
kprove  fvk/query_clone-spec.k                          # discharge; expect #Top
```

Expected: `(CLONE-REC)` and `(CLONE-ISO)` reduce to `#Top` for the linear/framing VCs;
the inductive `reach`-disjointness VC remains open at the `[ESCALATION BOUNDARY]` until the
separation-logic theory is supplied. Until then this proof is **constructed, not
machine-checked**.

## 7. Residual risk

- **Partial correctness + a discharged termination side condition.** Non-interference is
  established assuming the operations complete; `clone`'s recursion terminates by SC-1
  (finite acyclic operand graph, PO-3).
- **Trusted base.** (i) adequacy of the mini-X heap fragment as a model of CPython object
  identity + Django's `Query` attributes; (ii) that `set_values()`'s write-set is exactly
  the fields enumerated in PO-4 (verified by source inspection at this commit, but not
  itself mechanized); (iii) the reachability metatheory and `kprove`; (iv) the SMT /
  `[simplification]` oracle.
- **Escalation boundary.** The set-level disjointness over the inductive `reach` predicate
  (VC-disjoint) is **stated, discharged structurally, and routed**, not faked.
- **The "constructed, not machine-checked" caveat** applies; run §6 to upgrade.
