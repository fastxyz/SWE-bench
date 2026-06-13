# SPEC — parent-link collection for multi-table inheritance

**Target:** `repo/django/db/models/base.py`, `ModelBase.__new__`, the
`parent_links` collection loop (lines 194–219, as modified by the V1 fix).

**Companion K artifacts:** `fvk/mti_parent_links.k` (mini-X fragment semantics),
`fvk/mti_parent_links-spec.k` (the `(FOLD)` and `(SELECT-PL)` claims).
Status: **constructed, not machine-checked** (the MVP does not run
`kompile`/`kprove`; commands are in `fvk/PROOF.md`).

---

## 1. Intent (from PROBLEM.md, not from the code alone)

When a multi-table-inheritance child declares **several `OneToOneField`s to the
same parent**, Django must use the one explicitly flagged `parent_link=True` as
the MTI parent link — **regardless of the order the fields are declared in**. The
reported bug is that order decides which field is picked, so

```python
class Picking(Document):
    document_ptr = OneToOneField(Document, parent_link=True, related_name='+', on_delete=CASCADE)
    origin       = OneToOneField(Document, related_name='picking', on_delete=PROTECT)
```

raises `ImproperlyConfigured: Add parent_link=True to …Picking.origin`, while the
reverse declaration order works. The intent: the explicit `parent_link=True`
marker is authoritative; declaration order must not matter.

Intent evidence used: the issue title ("pk setup for MTI to parent get confused
by multiple OneToOne references"), the two code samples (one fails, one works),
the explicit "order seems to matter? … we have explicit parent_link marker", the
public hint about checking `field.remote_field.parent_link`, and the existing
contract test `invalid_models_tests…test_missing_parent_link` (a lone
non-parent-link OTO to the parent must still raise "Add parent_link=True").

## 2. What the loop computes (the model)

Filtering and the two nested loops produce a single **ordered, post-filter
sequence of candidate `OneToOneField`s**, `VS`. Each candidate is abstracted to
`field(K, PL, ID)`:

| symbol | meaning in the real code |
|---|---|
| `K`  | `make_model_tuple(resolve_relation(new_class, field.remote_field.model))` — the parent model the OTO points at |
| `PL` | `1` if `field.remote_field.parent_link` else `0` |
| `ID` | a unique field identity (lets "the result is one of the candidates" be stated) |

`parent_links` is a `Map : K ↦ field`. The loop folds `VS` left-to-right with the
**V1 update rule** (`updateSel` / `skip` in `mti_parent_links.k`):

```
existing := parent_links.get(K)
skip  ⟺  existing is not None  ∧  existing.PL = 1  ∧  field.PL = 0
if skip:  parent_links unchanged          # the `continue`
else:     parent_links[K] := field        # the assignment
```

## 3. Precondition (domain)

- `VS` is the post-filter candidate sequence: every element is an
  `OneToOneField` (so `remote_field.parent_link` exists — no `AttributeError`),
  in iteration order. Filters (`hasattr('_meta')`, concrete-parent skip,
  `isinstance(.., OneToOneField)`) are **assumed already applied** (Findings
  F-5/F-6).
- `PL ∈ {0, 1}` for every candidate (a boolean flag).
- Keys are well defined and stable: two OTOs pointing at the *same* parent model
  produce the *same* `K` (`resolve_relation`+`make_model_tuple` normalise class
  vs. string vs. `'self'` references). Unchanged from the original code.

## 4. Postcondition (the contract proved)

Let `C_K = candOf(VS, K)` be the candidates for parent key `K`, in order. After
the loop, for **every** key `K` that appears in `VS`:

- **(I1) well-formed choice.** `parent_links[K] ∈ C_K` — the chosen field is one
  of the actually-declared candidates (never invented).
- **(I2) parent-link priority, order-independent (the fix).**
  `parent_links[K].parent_link  ⟺  ∃ f ∈ C_K. f.parent_link`.
  Equivalently: if any candidate for `K` is `parent_link=True`, the chosen field
  is `parent_link=True`; and the chosen field is a parent link *only* if some
  candidate is. The biconditional holds **independently of where the parent-link
  field sits in `C_K`**.
- **(I3) legacy fall-back.** If *no* candidate for `K` is `parent_link=True`,
  `parent_links[K]` is the **last** candidate in `C_K` — exactly the pre-fix
  "last write wins" behaviour, which preserves
  `test_missing_parent_link`.
- **(D) domain preserved.** `keys(parent_links) = keysOf(VS)` — the *set of keys*
  is identical to the original implementation's. No parent that used to get an
  auto-created `*_ptr` loses it, and none newly does.

**Corollary (order independence — the headline property).** If exactly one
candidate for `K` has `parent_link=True` (the only valid MTI configuration), then
`parent_links[K]` is *that* field for every permutation of `C_K`. This is the
precise statement of "order must not matter".

## 5. Why both reported symptoms are covered

`parent_links[K]` becomes `new_class._meta.parents[parent]` (base.py:251–280),
consumed by:

- **`Options._prepare`** (options.py:241–257): promotes the parent link to the
  primary key and raises `ImproperlyConfigured` if it is not `parent_link=True`.
  I2 ⇒ the parent-link field is chosen ⇒ **no spurious error**.
- **`Model._set_pk_val`** (base.py:583–587): propagates the pk to each parent
  link's `target_field.attname`. With the correct field selected, the
  `*_ptr_id` column is populated ⇒ the secondary "`document_ptr_id` not
  populated" runtime symptom is **also** resolved.

## 6. Claims (formal, in `mti_parent_links-spec.k`)

- **(FOLD)** `select(VS)` from `⟨plinks⟩ M` reaches `⟨plinks⟩ foldSel(M, VS)` —
  the imperative loop equals the functional fold. Arithmetic-free; proved by
  guarded coinduction (induction on `VS`).
- **(SELECT-PL)** for a single-key candidate list `FS`, `foldSel(.Map, FS)[K]`
  satisfies I1 ∧ I2 ∧ I3. The selection-correctness theorem; proved by induction
  on `FS` (full hand proof in `fvk/PROOF.md`). The key-independence that lifts
  single-key correctness to the interleaved full list is Lemma KEY-INDEP
  (PROOF.md §4).

Default scope is **partial correctness**; the loop is a bounded `for` over a
finite list, so termination is immediate (noted, not separately proved — see
`fvk/PROOF.md` §6).
