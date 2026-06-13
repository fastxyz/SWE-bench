# SPEC.md — formal specification of the django-15128 fix

**Target:** `django/db/models/sql/query.py`, methods `Query.combine`,
`Query.bump_prefix`, `Query.change_aliases` (V1 fix applied).

**Status:** specifications constructed for the FVK audit; the K proof is
*constructed, not machine-checked* (FVK MVP — no `kompile`/`kprove` run).
Mode: **intent-spec** (align natural-language intent ↔ code ↔ formal spec) and
**partial correctness** (properties hold when the call returns; termination is a
separate recommendation).

The companion K artifacts are
[`combine-aliasing.k`](combine-aliasing.k) (mini-X semantics of the change_map
loop) and [`combine-aliasing-spec.k`](combine-aliasing-spec.k) (the claims).

---

## 0. Intent (from `benchmark/PROBLEM.md` and the public hints)

`qs1 | qs2` (and `&`) must not raise `AssertionError` inside
`Query.change_aliases`, and must produce a query equivalent to the one combine
intended before the crash. Root cause (confirmed by the maintainers' hints):
both operands default to the same `alias_prefix` `'T'`, so the relabelling map
combine builds can map an alias onto another alias that is itself still a key
(e.g. `{T4: T5, T5: T6}`), and that map then flows into a subquery's
`change_aliases`, whose first line requires keys and values be disjoint.

---

## 1. `change_aliases(change_map)` — contract

- **Precondition (the invariant every caller must establish):**
  `set(change_map).isdisjoint(change_map.values())` — the keys (old aliases) and
  the values (new aliases) are disjoint as sets.
- **Why it is a precondition, not a check to soften:** step 2 of the method
  renames `alias_map`/`table_map`/`alias_refcount` in a *sequential* loop; if an
  alias is both a key and a value it would be renamed twice (once as itself, once
  as another alias's target), so the relabelling would not be the intended
  one-to-one map. The `assert` documents and guards this requirement.
- **Postcondition (on the verified domain):** every reference to an `old` alias
  (in `where`, `select`, `group_by`, `annotations`, `alias_map`, `table_map`,
  `alias_refcount`, `external_aliases`, and recursively in subqueries) is
  replaced by `change_map[old]`, as a single simultaneous substitution.
- **V1 change:** added a comment explaining the assertion (the reporter asked for
  it). Behaviour unchanged.

## 2. `bump_prefix(other_query, exclude=None)` — contract

- **Precondition:** none beyond a well-formed `Query`; `exclude` is a set of
  aliases (default `None`, treated as the empty set).
- **Postcondition:**
  - If `self.alias_prefix != other_query.alias_prefix`: **no-op** (early return).
  - Otherwise: `self.alias_prefix` is set to a fresh prefix `P'` with
    `P' != other_query.alias_prefix` (the generator starts at the letter *after*
    the current prefix and skips any prefix already in `self.subq_aliases`), and
    **every alias of `self` except those in `exclude` is relabelled to
    `'%sN' % P'`** (a generated alias with the new prefix). Aliases in `exclude`
    keep their names.
- **V1 change:** added the `exclude` parameter and the
  `if alias not in exclude` filter; renamed the first parameter
  `outer_query → other_query`. Default behaviour (`exclude=None`) is identical to
  the previous code, so the existing subquery caller
  (`Query.resolve_expression`) is unaffected.

## 3. `combine(rhs, connector)` — contract (the fix)

- **Preconditions (enforced by the four `raise TypeError` guards, which are
  no-ops on the verified domain):** `self.model == rhs.model` (⇒ same base
  `db_table`, ⇒ `self.base_table` and `rhs.base_table` denote the *same* logical
  base table); `self` not sliced; equal `distinct`/`distinct_fields`.
- **Invariant established before the loop (the fix):** let `Ps =
  self.alias_prefix`. After the prefix-reconciliation step
  (`if self.alias_prefix == rhs.alias_prefix: rhs = rhs.clone();
  rhs.table_map = {…copy…}; rhs.bump_prefix(self, exclude={rhs.base_table})`),
  the (possibly cloned) `rhs` satisfies:
  - **(KEYS)** every non-base alias of `rhs` — i.e. every alias in
    `rhs_tables = list(rhs.alias_map)[1:]`, the only aliases that can become
    change_map keys — is a *generated* alias `pref(Pr, _)` whose prefix
    `Pr != Ps`.
- **Loop invariant (the circularity `(LOOP)`):** while building `change_map`,
  - every key in `change_map` is `pref(Pr, _)` with `Pr != Ps` *(from KEYS)*;
  - every value in `change_map` is `pref(Ps, _)` or a table-name alias `name(_)`
    *(from VALS: a value comes from `self.join`, which returns either a reused
    existing `self` alias — `self` has prefix `Ps`, so `pref(Ps,_)` or a `self`
    table-name — or a freshly generated `pref(Ps,_)` / first-occurrence
    `name(_)`)*.
- **Postcondition (the property the whole fix exists to guarantee):** the
  finished `change_map` satisfies
  `set(change_map).isdisjoint(change_map.values())`. Therefore every downstream
  `change_aliases(change_map)` — including the ones reached through queryset
  subqueries in `where` — meets its precondition (§1) and never asserts.
- **Non-mutation postcondition:** the object graph reachable from the *original*
  `rhs` argument is unchanged (the clone + `table_map` list-copy isolate every
  in-place mutation `bump_prefix`/`change_aliases` perform). Combine's docstring
  promise "`rhs` is not modified" is preserved.
- **Equivalence postcondition:** the combined query is identical to the one the
  pre-fix code *intended* to build (the bumped rhs prefix is only an intermediate
  relabelling; the final change_map values, and hence the final aliases, are the
  same generated `pref(Ps,_)` / table-name aliases as before — see PO-EQUIV).

---

## 4. Why disjointness holds — the one-paragraph proof

Keys are `pref(Pr, _)`; values are `pref(Ps, _)` or `name(_)`; and `Pr != Ps`.
A key `pref(Pr,n)` cannot equal a value `pref(Ps,m)` because the prefixes differ,
and cannot equal a value `name(t)` because the constructors differ. So no key
equals any value: `keys ∩ values = ∅`. This is `disjointKV` discharged by the
**core structural lemma** in `combine-aliasing-spec.k`. It is purely structural —
it needs neither arithmetic nor the (separate, standing) Django assumption that
real table names never look like `'<prefix><number>'`.

## 5. Side conditions / standing assumptions (full list in FINDINGS.md)

- **SC1 (Pr ≠ Ps).** `bump_prefix` chooses `Pr` strictly after `Ps` in the
  prefix sequence ⇒ `Pr != Ps`. Establishes KEYS' prefix-distinctness.
- **SC2 (KEYS).** After the bump, *all* of rhs's non-base aliases are generated
  `pref(Pr,_)` — bump relabels first-occurrence table names too — so there are
  **no** `name(_)` keys. (This is what also closes the otherwise-awkward
  name-vs-name corner case; see FINDINGS F4.)
- **SC3 (same base).** `self.base_table == rhs.base_table` (same model), so
  excluding `rhs.base_table` from the bump keeps the shared merge starting point
  consistent and the base is never a change_map key (`rhs_tables` skips it).
- **SC4 (no-bump branch).** When `self.alias_prefix != rhs.alias_prefix` the fix
  does nothing; disjointness still holds because reaching that branch means rhs
  already carries a non-default (bumped) prefix, whose relabelling left it with no
  `name(_)` non-base aliases either — same KEYS shape. This branch is effectively
  unreachable for top-level combine (see FINDINGS F4).
