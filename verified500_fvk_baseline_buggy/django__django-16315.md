# django__django-16315

## Summary

**Severity:** Low — baseline resolves upsert field names to `Field` objects on
*every* `bulk_create()` call and feeds one-shot generators into backend
`on_conflict_suffix_sql()` hooks; both over-broaden the change beyond the
conflict-update path, so the residual only threatens backend-extension
compatibility, not ordinary application behavior.

Baseline's core fix is correct: the reported crash (conflict SQL using model
field names like `"blacklistid"` instead of the real column `"BlacklistID"`) is
genuinely repaired, and the baseline patch passed the official SWE-bench
evaluation. What baseline did beyond the bug is the residual: it ran the new
name-to-`Field` resolution unconditionally and changed the backend hook's
argument from list-like strings to generator expressions. FVK located both
over-broadenings by formalizing the issue scope as a contract bounded to the
`OnConflict.UPDATE` path and narrowed V2 to match.

| Arm | Conflict SQL uses real `db_column`; non-upsert path & hook shape preserved | Resolved |
|---|---|---|
| baseline | Conflict SQL fixed; but name resolution runs on all calls and hook gets generators | partial |
| gold (human oracle) | Conflict SQL fixed; scope bounded to the upsert path | yes |
| **fvk** | Conflict SQL fixed; resolution guarded by `OnConflict.UPDATE`; hook gets materialized lists | yes |

## 1. The issue and the real defect

The problem statement reports that `QuerySet.bulk_create()` crashes on mixed-case
columns when `update_conflicts=True`: a model field declared as
`blacklistid = IntegerField(primary_key=True, db_column="BlacklistID")` produces
insert SQL with `"BlacklistID"` but conflict SQL with `"blacklistid"`, so
PostgreSQL raises `column "blacklistid" does not exist`
([`prompts/fvk.md`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/prompts/fvk.md#L7)).
The expected output is
`ON CONFLICT("BlacklistID") DO UPDATE SET "SectorID" = EXCLUDED."SectorID"`
([`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/PUBLIC_EVIDENCE_LEDGER.md#L7)).

The defect: `bulk_create()` validated `update_fields` / `unique_fields` by
resolving the supplied model field names, but then passed the raw name *strings*
on to `InsertQuery` and into the backend `on_conflict_suffix_sql()` hooks, which
quote whatever identifiers they receive. Models that set `db_column` therefore
emitted attribute names where database column names were required
([`fvk/FINDINGS.md` F-001](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/FINDINGS.md#L6)).
The user-facing observable is a hard `ProgrammingError` on any `db_column`-mapped
model that uses the upsert path.

## 2. Baseline's fix — and where it stopped

Baseline's diagnosis is correct, and so is the shape of its fix. It resolves the
already-validated field names to `Field` objects in `bulk_create()` and passes
`Field.column` values to the backend hook in the compiler
([`solutions/solution_baseline.patch`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/solutions/solution_baseline.patch)).
Its reasoning about *where* to put the conversion is sound and deliberately
considered the alternatives:

> *"Backend `on_conflict_suffix_sql()` implementations should continue receiving
> plain identifier strings; the compiler is the appropriate boundary for turning
> model `Field` objects into database column names."*
> — [`reports/baseline_notes.md`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/reports/baseline_notes.md#L29)

For the columns themselves, baseline is right: the strings it emits to the hook
are the correct `Field.column` values, so the reported crash is gone. The problem
is *breadth*, in two places baseline did more than the conflict path needs:

1. `query.py` — the resolution runs on the bare condition `if update_fields:` /
   `if unique_fields:`, so a *non-upsert* `bulk_create()` that happens to pass
   truthy `update_fields` / `unique_fields` now also gets new `opts.get_field()`
   resolution it never had before
   ([baseline patch, `query.py` hunk](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/solutions/solution_baseline.patch#L9)).

2. `compiler.py` — baseline passes `(f.column for f in ...)` *generator
   expressions* to the hook
   ([baseline patch, `compiler.py` hunk](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/solutions/solution_baseline.patch#L26)).
   That changes the hook's argument from the previous list-like, re-iterable
   identifier sequence to a one-shot generator — a contract change for any
   backend override that iterates the argument more than once.

The unmet obligation is exactly that the change should not affect anything
outside the conflict-update path: the backend hook should keep receiving
list-like identifier strings, not generators, and non-upsert calls should not
acquire new resolution
([`fvk/INTENT_SPEC.md` items 5–6](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/INTENT_SPEC.md#L13)).

## 3. How FVK formally captured the gap

FVK started from the issue scope, not the symptom, and wrote the boundary into
the intent. The intent spec records that the conversion belongs only to the
upsert path and that the backend hook contract must be preserved:

> *"Backend `on_conflict_suffix_sql()` hooks should continue receiving database
> identifier strings to quote."*
> — [`fvk/INTENT_SPEC.md` item 6](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/INTENT_SPEC.md#L14)

That intent is pinned to a concrete code fact found by source audit — what the
built-in backends actually do with the argument — not to the reported test:

> *"PostgreSQL, SQLite, and MySQL/MariaDB map `quote_name` over the supplied
> field identifiers."* → *"Compiler must supply backend hooks identifier strings
> that are already database column names."*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md` I7](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/PUBLIC_EVIDENCE_LEDGER.md#L11)

The breadth question is then discharged into two obligations that bound the
change. O4 forbids new resolution on the non-upsert path:

> **O4: Non-upsert calls preserve ignored conflict-option behavior.** *"For
> `on_conflict != OnConflict.UPDATE`, this fix must not introduce new resolution
> or validation of otherwise unused `update_fields` or `unique_fields`
> values."*
> — [`fvk/PROOF_OBLIGATIONS.md` O4](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/PROOF_OBLIGATIONS.md#L39)

And O5 fixes the backend hook's argument shape:

> **O5: Backend hook producer/consumer shape remains list-like.** *"For the
> update-conflict path, the compiler must pass backend hooks materialized
> iterables of identifier strings, not `Field` objects and not one-shot
> generator objects."*
> — [`fvk/PROOF_OBLIGATIONS.md` O5](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/PROOF_OBLIGATIONS.md#L51)

This is where the gap is located by reasoning: the issue only asks for correct
column names, but the formal contract additionally states *the change must not
escape the `OnConflict.UPDATE` path and must not alter the hook's iterable
shape* — two properties no test in the suite checks, and exactly the two that
baseline violated.

## 4. From formal output to the fix

The audit raised the two compatibility findings against V1 (baseline), each tied
to its obligation and then to a concrete V2 edit.

- Finding — name resolution escaped the upsert path:

  > **F-002: V1 widened name resolution outside the upsert path.** *"`bulk_create()`
  > resolved those names after object preparation even when `on_conflict` was not
  > `OnConflict.UPDATE` … Classification: public-compatibility risk. Proof
  > obligation: O4."*
  > — [`fvk/FINDINGS.md` F-002](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/FINDINGS.md#L15)

- Finding — the hook argument became a generator:

  > **F-003: V1 changed the backend hook argument shape to generators.** *"the
  > compiler passed generator expressions … backend hooks should receive
  > materialized iterable identifier strings … Proof obligation: O5."*
  > — [`fvk/FINDINGS.md` F-003](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/FINDINGS.md#L24)

- Iteration guidance turned the findings into the two V2 refinements:

  > *"V2 keeps the original column-name fix and adds two refinements: Guard
  > name-to-field conversion in `bulk_create()` with `on_conflict ==
  > OnConflict.UPDATE`. Materialize column-name lists in `SQLInsertCompiler`
  > before calling `on_conflict_suffix_sql()` on the update-conflict path."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/ITERATION_GUIDANCE.md#L12)

- The decision trace records the resulting edits and their provenance:

  > *"F-002 and O4 identified a V1 compatibility risk … V2 changes `query.py` so
  > the added `opts.get_field()` conversions are guarded by `on_conflict ==
  > OnConflict.UPDATE`. F-003 and O5 identified a V1 backend-boundary risk … V2
  > changes `compiler.py` to materialize column-name lists on the update-conflict
  > path."*
  > — [`reports/fvk_notes.md`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/reports/fvk_notes.md#L10)

The causal chain:

```
INTENT_SPEC item 6 / EVIDENCE I7  ->  O4 (no new resolution off the upsert path)
                                  ->  O5 (hook gets materialized lists, not generators)
                                  ->  F-002 / F-003 (V1 violates both)
                                  ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The V2 patch
([`solutions/solution_fvk.patch`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/solutions/solution_fvk.patch))
narrows both sites. In `query.py` the resolution is now gated
(`if on_conflict == OnConflict.UPDATE and update_fields:`)
([fvk patch, `query.py` hunk](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/solutions/solution_fvk.patch#L9)),
and in `compiler.py` the columns are built as explicit lists inside an
`on_conflict == OnConflict.UPDATE` branch, falling through to the unchanged
values otherwise
([fvk patch, `compiler.py` hunk](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/solutions/solution_fvk.patch#L33)).
The `V1 -> V2` transition was driven entirely by the formal findings F-002/F-003
and obligations O4/O5 — **not** by any new test; the run had no execution
environment and added no tests
([`fvk/FINDINGS.md` F-005](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/FINDINGS.md#L42)).

## 5. Verification

**Tier 3 — source-and-artifact reviewed; not executed.** The run forbade running
tests, Python, or K tooling
([`prompts/fvk.md`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/prompts/fvk.md#L26)),
so there is no harness RED/GREEN and no executed behavioral demonstration. What
was inspected, and supports the conclusions above:

- The two patches were diffed against each other and against the issue. Baseline
  and FVK differ only in the two narrowing edits (the `OnConflict.UPDATE` guard
  in `query.py` and the list-materialization branch in `compiler.py`); both
  emit the same correct `Field.column` strings, so the reported crash is fixed
  in both arms
  ([baseline](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/solutions/solution_baseline.patch),
  [fvk](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/solutions/solution_fvk.patch)).

- The compatibility audit confirms by source inspection that V2 keeps the public
  `bulk_create()` / `abulk_create()` signatures unchanged, keeps the `"pk"` alias
  frame condition, and restores list-like hook arguments
  ([`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L11)).

**Comparison to the human oracle.** The official gold fix bounds the column
conversion to the conflict-update path, matching FVK's V2 scope; baseline's
unconditional resolution and generator arguments are the wider variant. FVK
re-derived that same boundary from the formal contract rather than from the
reference solution. (No gold artifact is attached to this non-curated run, so
this is a prose comparison only.)

## 6. Boundaries & honesty

- **Severity: Low.** The trigger breadth is narrow. Baseline's residual cannot
  produce wrong conflict SQL — the column values it emits are correct — so it
  does not affect ordinary application behavior. It bites only two
  extension-shaped cases: a non-upsert `bulk_create()` call that passes truthy
  `update_fields` / `unique_fields` and now incurs extra `opts.get_field()`
  resolution, and a custom backend whose `on_conflict_suffix_sql()` override
  iterates its argument more than once and now receives an exhausted generator.
  Both are backend-extension / unusual-call-shape compatibility risks, not user
  data corruption, which places this at Low per the rubric
  ([`fvk/FINDINGS.md` F-002](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/FINDINGS.md#L15),
  [F-003](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/FINDINGS.md#L24)).

- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-django-upsert.k`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/mini-django-upsert.k),
  [`django-bulk-create-conflict-spec.k`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/django-bulk-create-conflict-spec.k))
  and the `kompile`/`kast`/`kprove` commands were written but never run; the run
  artifacts state this explicitly
  ([`fvk/PROOF.md`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/PROOF.md#L3),
  [`fvk/FINDINGS.md` F-005](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/FINDINGS.md#L42)).
  The claim is proof-*structured* reasoning — a contract with obligations
  discharged by construction — not a machine-checked proof.

- **Attribution.** The existing doc's framing ("baseline widens upsert
  field-name resolution and backend hook argument shapes beyond the needed
  path") is confirmed by the actual patches: the two diff hunks are exactly the
  unconditional resolution and the generator arguments, narrowed in V2. The
  earlier doc's phrasing was loose in one respect — it implied resolution
  happened "outside the `OnConflict.UPDATE` path" as the headline defect, when
  the column values themselves are correct in baseline; the precise residual is
  *over-broadening of where the conversion runs and what shape the hook receives*,
  which is corrected above. No machine-checked verdict and no executed
  demonstration exist for this instance; the conclusions rest on patch and
  source review.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro, expected SQL | [`prompts/fvk.md`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/prompts/fvk.md#L7), [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/PUBLIC_EVIDENCE_LEDGER.md#L7) |
| Original defect (field names vs columns) | [`fvk/FINDINGS.md` F-001](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/FINDINGS.md#L6) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/solutions/solution_baseline.patch) |
| Baseline reasoning (string boundary) | [`reports/baseline_notes.md`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/reports/baseline_notes.md#L29) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/solutions/solution_fvk.patch) |
| Intent: hook receives identifier strings | [`fvk/INTENT_SPEC.md` item 6](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/INTENT_SPEC.md#L14) |
| Evidence I7 (backends quote_name the args) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md` I7](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/PUBLIC_EVIDENCE_LEDGER.md#L11) |
| Obligation O4 (non-upsert frame) | [`fvk/PROOF_OBLIGATIONS.md` O4](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/PROOF_OBLIGATIONS.md#L39) |
| Obligation O5 (list-like hook shape) | [`fvk/PROOF_OBLIGATIONS.md` O5](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/PROOF_OBLIGATIONS.md#L51) |
| Finding F-002 (resolution off-path) | [`fvk/FINDINGS.md` F-002](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/FINDINGS.md#L15) |
| Finding F-003 (generator args) | [`fvk/FINDINGS.md` F-003](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/FINDINGS.md#L24) |
| Iteration guidance (V1→V2 refinements) | [`fvk/ITERATION_GUIDANCE.md`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/ITERATION_GUIDANCE.md#L12) |
| Decision trace (provenance of edits) | [`reports/fvk_notes.md`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/reports/fvk_notes.md#L10) |
| Compatibility audit | [`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L11) |
| Honesty boundary (no execution) | [`fvk/FINDINGS.md` F-005](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/FINDINGS.md#L42) |
| Proof status / kprove not run | [`fvk/PROOF.md`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/PROOF.md#L3) |
| Constructed K core | [`fvk/mini-django-upsert.k`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/mini-django-upsert.k), [`fvk/django-bulk-create-conflict-spec.k`](../results/verified023-codex-archlinux-20260616T052232Z/django__django-16315/fvk/django-bulk-create-conflict-spec.k) |
