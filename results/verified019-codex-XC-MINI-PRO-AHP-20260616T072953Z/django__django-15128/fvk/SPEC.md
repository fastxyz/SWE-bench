# FVK Spec for django__django-15128

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audit targets the V1 changes in `repo/django/db/models/sql/query.py`:

- `Query.combine()` normalizes the right-hand query before join merging when
  both sides share an alias prefix.
- `Query.bump_prefix()` accepts `exclude` so the initial alias can be preserved
  while all other RHS aliases are relabeled.

The observable under audit is the alias relabeling contract required before
`Query.change_aliases()` or nested query relabeling sees a `change_map`.

## Intent Spec

I-1. `QuerySet.__or__` / `Query.combine(..., OR)` must not raise
`AssertionError` merely because the two operands have compatible models and
overlapping alias-prefix-generated names. Evidence: the issue reports
`qs1 | qs2` raising in `Query.change_aliases()` with
`change_map = {'T4': 'T5', 'T5': 'T6'}` and asks to fix it.

I-2. The RHS aliases should be made collision-free before `combine()` builds
the merge `change_map`. Evidence: the public hint says the root cause is that
both queries share `alias_prefix`, and recommends changing the RHS prefix and
aliases before creating the `change_map`.

I-3. The initial RHS alias must remain unchanged for `combine()`. Evidence: the
public hint says the alias merging algorithm requires both queries to share the
same initial alias and that the fix should adjust all aliases except the
initial one.

I-4. Alias generation must remain deterministic and compatible with existing
subquery-prefix logic. Evidence: the public discussion rejects random prefixes
and rotating one-letter prefixes, and points to `Query.bump_prefix()` as the
existing collision-avoidance mechanism.

I-5. `combine()` must not mutate `rhs`. Evidence: `Query.combine()`'s docstring
says "`rhs` is not modified during a call to this function."

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E-1 | prompt | "`qs1 | qs2` ... `AssertionError` ... `change_map = {'T4': 'T5', 'T5': 'T6'}`" | Prevent overlapping relabel-map keys and values in the reported OR combine. | Encoded by PO-1, PO-3, PO-4. |
| E-2 | prompt analysis | "related table_names also exist in lhs.table_map" causing `T5` and `T6` allocation | Normalize RHS before LHS alias allocation builds the combine map. | Encoded by PO-3. |
| E-3 | public hint | "change the alias_prefix of the rhs and change its alias accordingly" | Use prefix bumping on RHS, not global `table_alias()` randomization. | Encoded by PO-2. |
| E-4 | public hint | "adjust all the aliases but the initial one" | Preserve RHS base alias. | Encoded by PO-2. |
| E-5 | code docstring | "`rhs` is not modified" | Clone and isolate mutable alias-list state before relabeling RHS. | Encoded by PO-5. |
| E-6 | public discussion | Random or cyclic prefixes fail other cases | Preserve deterministic prefix generation and subquery-prefix awareness. | Encoded by PO-6. |

## Formal Model

The K abstraction in `fvk/mini-query-alias.k` models only the alias facts needed
for this issue:

- `AliasList`: ordered aliases in `alias_map`.
- `AliasSet`: aliases excluded from relabeling, used prefixes, keys, and values.
- `ChangeMap`: old alias to new alias.
- `bumpExcept(prefix, aliases, exclude, used)`: the abstract behavior of
  `Query.bump_prefix(..., exclude=...)`.
- `combineNormalize(lhs_prefix, lhs_aliases, rhs_prefix, rhs_aliases, used)`:
  the pre-merge normalization step V1 adds to `Query.combine()`.

The abstraction intentionally does not model SQL generation, join promotion,
WHERE tree internals, or query execution. Those are outside the reported
failure; the discriminator property is whether the alias map before relabeling
can express the bad state `keys(change_map) intersect values(change_map)`.

## K Claims in English

C-1. `bumpExcept()` returns a new prefix and change map such that
`keys(change_map)` and `values(change_map)` are disjoint, generated values do
not overwrite excluded aliases, and excluded aliases remain unchanged.

C-2. `combineNormalize()` on two queries with the same alias prefix preserves
the initial RHS alias and produces a normalized RHS alias list whose subsequent
combine relabel map has disjoint keys and values.

## Adequacy Audit

| Claim | Intent coverage | Verdict |
| --- | --- | --- |
| C-1 | Covers I-2, I-3, I-4 by making RHS aliases collision-free while preserving the initial alias. | Pass. |
| C-2 | Covers I-1 by excluding the reported overlapping-map shape before merge relabeling. | Pass. |
| RHS clone frame | Covers I-5 by ensuring relabeling happens on an isolated clone. | Pass. |
| SQL/result semantics | Not claimed; issue concerns construction-time alias relabeling, not database result equivalence. | Out of scope for this FVK slice. |

## Public Compatibility Audit

- `Query.bump_prefix()` gains an optional `exclude=None` parameter. Existing
  callers at `query.py:1057` and `query.py:1818` call it positionally with only
  `outer_query`, so they retain old behavior with `exclude=()`.
- The new `combine()` call uses the optional keyword internally only.
- `Query.combine()` retains its public signature and keeps the documented RHS
  non-mutation behavior by cloning RHS and copying `table_map` alias lists
  before relabeling the clone.

## Domain and Assumptions

- The proof is partial correctness over successful `combine()` calls after the
  existing model/slice/distinct compatibility checks pass.
- The alias namespace follows Django's existing convention: generated aliases
  are represented by the query alias prefix plus a numeric suffix; physical
  table names and filtered relation aliases are treated as the existing ORM
  alias namespace, not a new concern introduced by this patch.
- Termination of `prefix_gen()` is not machine-proved here; the existing
  recursion-limit guard is retained.
