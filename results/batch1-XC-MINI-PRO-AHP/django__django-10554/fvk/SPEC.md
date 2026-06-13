# SPEC — `Query.clone()` isolation of combined queries (django__django-10554)

> Constructed with the Formal Verification Kit `/formalize` workflow. Artifacts
> are **constructed, not machine-checked** (MVP: no `kompile`/`kprove` run).
> K files: [`query_clone.k`](query_clone.k), [`query_clone-spec.k`](query_clone-spec.k).

## 1. What is being specified, and why

The V1 fix changes one function — `django/db/models/sql/query.py :: Query.clone()`
— to deep-copy `combined_queries`:

```python
if self.combined_queries:
    obj.combined_queries = tuple(query.clone() for query in self.combined_queries)
```

`clone()` is the single copy primitive for `Query`: `chain()`, `relabeled_clone()`,
`__deepcopy__()`, and `QuerySet._clone()` all route through it (verified — see
`PROOF_OBLIGATIONS.md` PO-5). So specifying `clone()` specifies *every* way a query
is copied.

This is **not** an arithmetic contract; it is an **object-aliasing / non-interference**
contract. The relevant intent (issue #10554 + its hint *"a `.query` attribute change
without performing a prior `copy()` of the query/queryset"*) is:

> Copying a set-operation query must yield a copy whose combined operand queries are
> **independent objects**, so that mutating one queryset's combined queries during
> evaluation cannot corrupt another queryset that was built from the same operands.

The mutation that makes independence matter is in
`SQLCompiler.get_combinator_sql()` (`compiler.py:430`): when a combinator query is
compiled with a `values()/values_list()` column list, it calls `set_values()` on each
combined query to reset its selected columns to the outer column list. If a combined
`Query` object is **shared** between the original union and a derived queryset, that
reset is visible to both, and the original later emits a reduced column list while its
combinator `ORDER BY` still references a (now out-of-range) column position →
`ORDER BY position N is not in select list`.

## 2. The model (mini-X fragment)

`query_clone.k` models the minimal fragment the fix touches: a heap `<objs>` of
mutable objects `obj(cols, comb)` (selected-column list + list of combined-query ids),
a fresh-id allocator `<next>`, and three operations:

| construct | models | semantics |
|---|---|---|
| `clone(o)` | `Query.clone()` | allocate a **fresh** id; copy `cols`; set `comb := [clone(c) for c in o.comb]` (the V1 deep copy) |
| `setvals(o, v)` | `set_values()` during compilation | `o.cols := v` **in place** (every alias of `o` sees it) |
| `colsOf/combOf` | attribute reads | read the object's fields |

`clone` is **recursive** (it clones each combined operand), so its contract is a
**recursion circularity** (`reachability-and-circularities.md` §3, the `(REC)` shape).

## 3. The contracts (claims in `query_clone-spec.k`)

**(CLONE-REC) — the recursion contract / circularity.**
*Precondition:* root `R` is a live object; the `comb`-graph under `R` is **finite and
acyclic**; every id reachable from `R` is below the allocator high-water mark `N0`.
*Postcondition:* `clone(R)` returns a **fresh** root `?R ≥ N0`; the heap grows by
exactly one fresh object per node of `reach(R)`; and

```
reach(OBJS', ?R) ∩ reach(OBJS, R) = ∅      and      every id in reach(?R) ≥ N0.
```

i.e. the cloned object graph is **disjoint** from the source graph.

**(CLONE-ISO) — the whole-fix non-interference contract** (derived from CLONE-REC).
After `c = clone(q)`, for any value `V` and any object `M` reachable from `c`,
`setvals(M, V)` leaves the `cols` of **every** object reachable from `q` unchanged:

```
preservedOn(reach(q), OBJS_before, OBJS_after)  =  true.
```

This is exactly the property that makes a re-evaluation of the original `q` safe after a
derived queryset `c` has been evaluated (and has reset its own combined queries).

## 4. Preconditions / side conditions (the audit's real output)

The clean statement of CLONE-REC forces three side conditions; each is a checkable fact
about the Django code (discharged in `PROOF_OBLIGATIONS.md`):

- **SC-1 (finite, acyclic combined-query graph).** `combined_queries` are built in
  `_combinator_query` from *pre-existing* querysets, which cannot transitively contain
  the query being constructed ⇒ a finite DAG with no back-edge ⇒ `clone`'s recursion
  terminates. (PO-3.)
- **SC-2 (fresh allocation).** `clone()` starts with `obj = Empty()` — a brand-new
  object — for the root *and*, via the recursive `query.clone()`, for every combined
  query. Freshness is what gives disjointness. (PO-1.)
- **SC-3 (clone is deep *enough* for the mutation).** `set_values()` only ever
  *rebinds* attributes (`select`, `values_select`, `default_cols`, `deferred_loading`)
  or mutates objects that `clone()` already deep-copies (`alias_map`, the
  `*_select_mask`s). It never mutates a tuple/list shared with the original in place.
  Hence cloning at the `Query`-object granularity is sufficient — the column tuples
  themselves need not be copied. (PO-4.)

## 5. Scope

Partial-correctness style: the contract says *if* a clone/evaluation completes, the
isolation/non-interference holds. Termination of `clone`'s recursion is covered by SC-1
(finite acyclic graph) and noted as a discharged total-correctness side obligation.
