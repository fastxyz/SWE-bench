# FINDINGS.md — django-15128 (FVK audit of the V1 fix)

Plain-language findings, each as `input → observed vs expected`. The Findings
report does **not** depend on machine-checking. Classification tags:
`[BUG]` `[FIXED-IN-V1]` `[PRECOND]` `[ASSUMPTION]` `[CORNER]` `[PERF]`
`[BACKCOMPAT]` `[ESCALATION]`.

---

## A. Intent ↔ code findings (from `/formalize`)

### F1 `[BUG] [FIXED-IN-V1]` — the original defect: intersecting change_map
- **input:** `qs1 | qs2` where both queries default to `alias_prefix = 'T'` and
  the lhs already contains the tables the rhs re-references, and the rhs `where`
  contains a queryset subquery (e.g. `Q(bars__baz__in=qux.bazes.all()) | …`).
- **observed (pre-fix):** `combine` builds `change_map = {T4: T5, T5: T6}` (a new
  alias `T5` minted for rhs's `T4` equals rhs's own not-yet-relabelled `T5`).
  That map is propagated into the subquery via `where.relabel_aliases`, reaching
  `Query.change_aliases`, whose `assert set(change_map).isdisjoint(
  change_map.values())` fails → `AssertionError`.
- **expected:** a relabelling whose keys and values are disjoint, applied without
  error; `qs1 | qs2` returns the same rows as `qs2 | qs1`.
- **resolution:** V1 bumps the rhs aliases to a distinct prefix before building
  the map (see §C). Verified disjoint by SPEC §4 + the core lemma.

### F2 `[PRECOND]` — `change_aliases` requires disjoint keys/values, undocumented
- **input:** any `change_map` with a key that is also a value, e.g.
  `{T4: T5, T5: T6}`.
- **observed:** step 2 of `change_aliases` renames `alias_map`/`table_map`
  entries in a sequential loop; an alias that is both key and value is renamed
  twice, so the result is **not** the intended one-to-one substitution (and the
  `assert` fires first). Pre-V1 this precondition was completely undocumented —
  exactly the "missing precondition" smell `/formalize` is meant to surface.
- **expected / action:** the precondition is real and worth keeping as an
  `assert`; V1 adds a comment stating it (the reporter explicitly requested this)
  and makes `combine` *establish* it rather than rely on luck. **Kept** as an
  invariant; see PO-DISJOINT.

### F3 `[PRECOND] [ASSUMPTION]` — `combine` assumes a shared base alias
- **input:** any `combine(rhs, …)`.
- **observed:** the loop does `rhs_tables = list(rhs.alias_map)[1:]` (skips rhs's
  base) and adds `rhs.where` without remapping rhs's base alias, i.e. it assumes
  `rhs`'s base alias already equals `self`'s base alias.
- **expected:** holds because the first guard requires `self.model == rhs.model`,
  so both base tables are the same `db_table` and (for the unbumped top-level
  queries combine receives) the same base-table-name alias.
- **why it matters for V1:** the fix excludes `rhs.base_table` from the bump
  precisely to preserve this shared starting point (SPEC §3 SC3). Had the bump
  relabelled the base (as the un-`exclude`d `bump_prefix` does for subqueries),
  rhs's base would become e.g. `U0` while self's stayed the table name, breaking
  the merge. **Excluding the base is necessary, not cosmetic.**

### F4 `[CORNER]` — the name-vs-name collision, and why it cannot occur
- **input (hypothetical):** could a change_map key and value collide as two
  identical *table-name* aliases `name(app_bar)` rather than as `T?`/`T?`?
- **analysis:** a table-name value can arise (e.g. an rhs join *reusing* self's
  first-occurrence `app_bar` alias). For it to collide it would also have to be a
  *key*. After V1's bump, **rhs has no `name(_)` keys at all** — `bump_prefix`
  relabels *every* non-base alias, including first-occurrence table names, to
  `pref(Pr,_)` (SPEC §3 KEYS / SC2). So every key is a generated alias and no
  key is a table name; the name-vs-name collision is structurally impossible in
  the bumped (reachable) branch.
- **no-bump branch:** when `self.alias_prefix != rhs.alias_prefix` the fix does
  nothing. Reaching that branch means rhs already had a non-default prefix, which
  only happens via a prior `bump_prefix` that *also* prefixed all its non-base
  aliases — so again no `name(_)` keys, and disjointness holds. Moreover, for
  *top-level* `combine` operands (the only callers — `QuerySet.__or__`/`__and__`)
  `alias_prefix` is always the class default `'T'`, so this branch is in practice
  **unreachable**. **No action needed**; documented so the reasoning is on record.

### F5 `[ASSUMPTION]` — generated aliases vs. real table names (NOT relied upon)
- **input:** a database table literally named like a generated alias, e.g.
  `"T4"`.
- **observed:** Django's whole aliasing scheme assumes real table names never
  equal `'<prefix><number>'`. The V1 *disjointness* proof does **not** depend on
  this (keys vs values differ by prefix or by constructor shape — SPEC §4), so
  the fix neither strengthens nor weakens this standing assumption. Recorded for
  completeness; out of scope.

---

## B. Proof-derived findings (from `/verify`)

### F6 `[BUG] [FIXED-IN-V1]` — rhs would be corrupted without the table_map copy
- **input:** `qs1 | qs2` (prefixes equal) where `rhs = qs2.query` has a table
  with two aliases, e.g. `table_map['app_bar'] == ['app_bar', 'T4']`.
- **observed (naïve fix: `rhs = rhs.clone(); rhs.bump_prefix(...)` with no copy):**
  `Query.clone()` only *shallow*-copies `table_map`, so the clone's list values
  are the **same list objects** as the original's. `change_aliases` mutates those
  lists in place (`table_aliases[pos] = new_alias`), so bumping the clone
  rewrites `qs2.query.table_map['app_bar']` to `['U1','U3']` while
  `qs2.query.alias_map` still says `app_bar`/`T4`. The caller's `qs2` is left
  internally inconsistent; a later `qs2.filter(...)` can then read a stale alias
  from `table_map` and raise `KeyError` / build wrong SQL.
- **expected:** `combine` must not mutate `rhs` (its docstring guarantees this).
- **resolution:** V1 reassigns
  `rhs.table_map = {t: aliases.copy() for t, aliases in rhs.table_map.items()}`
  on the clone before bumping, giving the clone independent lists. This is the
  **only** remaining shared-mutable structure: `clone()` already gives fresh
  `alias_map`/`alias_refcount` dicts and an independent `where`; `change_aliases`
  *reassigns* (not mutates) `select`/`annotations`/`external_aliases`/`group_by`
  to new objects; and `alias_map` values are replaced via `relabeled_clone`
  (new `Join` objects), never mutated. See PO-NOMUT.

### F7 `[BACKCOMPAT]` — `bump_prefix`'s new parameter is a safe extension
- **input:** the existing call sites `clone.bump_prefix(query)`
  (`resolve_expression`) and `query.bump_prefix(self)` (`split_exclude`).
- **observed:** both pass the query positionally; `exclude` defaults to `None`,
  normalized to `{}`, and `alias not in {}` is always true, so **all** aliases
  are relabelled exactly as before. The parameter rename `outer_query →
  other_query` is keyword-incompatible only for callers using `outer_query=…`;
  a repo-wide search finds none (the method is internal). **No regression.**

### F8 `[CORNER]` — empty / single-alias rhs
- **input:** `rhs.alias_map` with only the base entry (a single-table queryset),
  or empty.
- **observed:** `rhs.base_table` is the sole entry (or `None` if empty);
  `exclude={rhs.base_table}` makes the bump's change_map empty (everything is
  excluded / absent), `rhs_tables` is `[]`, the loop body never runs, and the
  resulting `change_map` is `{}` — trivially disjoint. Correct, no crash.

---

## C. The V1 change set (what was actually edited)

| Location | Edit | Justified by |
|---|---|---|
| `change_aliases` | comment explaining the disjointness `assert` | F2 |
| `bump_prefix` | add `exclude=None`; `if alias not in exclude` filter; rename `outer_query→other_query` | F1, F3, F7 |
| `combine` | when prefixes match: `rhs = rhs.clone()`, copy `table_map` lists, `rhs.bump_prefix(self, exclude={rhs.base_table})` | F1, F3, F6 |

---

## D. Findings that are *not* code bugs (recorded, no action)

### F9 `[PERF]` — unconditional clone on prefix match
- **input:** a simple `qs.filter(a=1) | qs.filter(b=2)` (no joins; both prefix
  `'T'`).
- **observed:** the fix clones `rhs` and copies its `table_map` even though
  `rhs_tables` is empty and the bump is a no-op, so the work is wasted.
- **assessment:** a *performance* observation, not a correctness defect (partial
  correctness says nothing about cost). The output is identical with or without
  the clone in this case (PO-EQUIV). A provably-safe guard
  (`and len(rhs.alias_map) > 1`) could skip it. **Decision: keep V1 unguarded**
  for minimality/clarity; the clone cost is comparable to the `_chain()`
  `QuerySet.__or__` already performs and combine is not a hot loop. Flagged so
  the trade-off is on record. See ITERATION_GUIDANCE.md.

### F10 `[CORNER] [ESCALATION]` — pre-existing `'Z'` prefix wraparound
- **input:** a query whose `alias_prefix` has reached `'Z'` (≈25+ levels of
  prefix bumping).
- **observed:** `prefix_gen` computes `chr(ord('Z')+1) = '['` and then
  `alphabet.index('[')` raises `ValueError`. This is **pre-existing** behaviour
  of `bump_prefix`, untouched by V1. **V1 does not worsen it:** the fix bumps a
  *fresh rhs clone by one level* and never bumps `self`, so prefixes do not
  accumulate across chained `|`/`&` (each `combine` independently maps
  `'T' → 'U'`). Out of scope for this ticket; noted for completeness.

---

## E. Verdict

Every proof obligation in `PROOF_OBLIGATIONS.md` is discharged for the **reachable
(bumped) branch** by the constructed proof; the no-bump branch is shown
unreachable/defensive and also disjoint (F4). The audit surfaced **no new code
bug in V1** and confirmed two design-critical subtleties the fix already handles
correctly (base-exclusion F3, table_map copy F6). **V1 stands** (the only
candidate change, F9, is a non-correctness perf tweak deliberately declined).
