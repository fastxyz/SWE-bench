# SPEC.md — parent-link selection in MTI (`ModelBase.__new__`)

Target: the `parent_links` collection loop in
`repo/django/db/models/base.py` (`ModelBase.__new__`), as patched by V1, plus
the consumer `Options._prepare()` in `repo/django/db/models/options.py`.

Formal core: [`mini-python.k`](mini-python.k) (semantics fragment) and
[`parent-links-spec.k`](parent-links-spec.k) (claims). This note consolidates,
as labelled sections, the adequacy artifacts the FVK methodology requires
(`INTENT_SPEC`, `PUBLIC_EVIDENCE_LEDGER`, `FORMAL_SPEC_ENGLISH`, `SPEC_AUDIT`,
`PUBLIC_COMPATIBILITY_AUDIT`).

---

## 1. INTENT_SPEC (intent-only, written before reading the candidate)

What the *public* intent requires of MTI parent-link selection, independent of
what V1 happens to do:

- **I1 (winner / ordering).** When a child model in multi-table inheritance
  declares several `OneToOneField`s pointing at the same parent, and one of them
  is explicitly marked `parent_link=True`, *that* field is the link to the
  parent. The choice must **not** depend on the order in which the fields are
  declared.
- **I2 (explicit marker is authoritative & documented).** A `OneToOneField` to
  the parent is treated as a candidate parent link; Django requires it to be
  marked `parent_link=True`. Implicit promotion of an unmarked `OneToOneField`
  was deprecated and removed — an unmarked field selected as the parent link
  must raise `ImproperlyConfigured: Add parent_link=True to <field>`.
- **I3 (auto link).** If the child declares no parent link to the parent, Django
  auto-creates `…_ptr = OneToOneField(parent, parent_link=True, primary_key=True)`.
- **I4 (preservation / frame).** Every MTI configuration that is valid today must
  keep working unchanged; the fix only resolves the multiple-reference ambiguity.
- **I5 (pk consistency).** The field recorded as the parent link
  (`Model._meta.parents[parent]`) must be the same field that becomes the model's
  primary key, so the parent pointer column is populated (no "…_ptr not
  populated" breakage).

Observed candidate behavior is recorded in §2 only as "to check," never as an
expected value by itself.

## 2. PUBLIC_EVIDENCE_LEDGER (intent ledger)

| ID | Source | Quoted evidence | Semantic obligation | Status |
|----|--------|-----------------|---------------------|--------|
| E1 | prompt | "pk setup for MTI to parent get confused by multiple OneToOne references." + the `Picking` example where `document_ptr(parent_link=True)` then `origin` "produces … ImproperlyConfigured: Add parent_link=True to … origin" while the reverse order "Works" | **Ordering/winner** (`override`, `precedence`): explicit `parent_link=True` must win regardless of declaration order (I1) | Encoded — `(SELECT)` `containsTrue(L) ⇒ result = firstTrue(L)`; `(CASE-A)`/`(CASE-B)` |
| E2 | prompt | "order seems to matter? … we have explicit parent_link marker … shouldn't it look from top to bottom" | order must not change the winner; explicit marker is the discriminator (I1) | Encoded (order-independence of winner) |
| E3 | prompt/hint (S. Charette) | "Not sure why we're not checking … field.remote_field.parent_link on parent links connection." | implementation hint: consult `parent_link` during collection | Informs mechanism; not taken as a verbatim spec (see F1, F-ALT) |
| E4 | prompt/hint | "the automatically added `place_ptr` field end up with `primary_key=True`" / "It does go away [with] primary_key" | the parent link is the pk; explicit field must become pk (I5) | Encoded indirectly via consumer `_prepare()` |
| E5 | prompt/hint | "simpler case … `some_unrelated_document = OneToOneField(Document, …)` … Produces the same error." | A thread participant deems the **lone-unmarked** error a bug | **SUSPECT** — conflicts with E6/docs; resolved in F1 |
| E6 | docs | `docs/releases/1.10.txt`: "implicit promotion of a `OneToOneField` to a `parent_link` is deprecated. Add `parent_link=True` to such fields." `docs/internals/deprecation.txt` (2.0): "… will be removed." | I2: unmarked selected field ⇒ error; do **not** silently auto-create | Encoded — `(CASE-LONE)` + `_prepare()` error preserved |
| E7 | docs | `docs/topics/db/models.txt`: "You can override that field by declaring your own `OneToOneField` with `parent_link=True`." | the explicit `parent_link` field is the authoritative link (I1/I2) | Encoded |
| E8 | public-test | `tests/invalid_models_tests/test_models.py::test_missing_parent_link` asserts `Add parent_link=True to … ParkingLot.parent` | I2 for the lone-unmarked case | Kept (positive doc evidence E6); marked SUSPECT-but-upheld in F1 |
| E9 | public-test | `tests/model_inheritance/tests.py::test_abstract_parent_link` — abstract base parent link `a` ⇒ `C._meta.parents[A] is a` | I1 across an abstract base | Encoded — covered by `(LOOP)` cross-base reasoning |
| E10 | code | V1 store-guard `existing is not None and existing.remote_field.parent_link` over `reversed([new_class] + parents)` × `local_fields` | state/transition shape for the model | from_code (modelled, not intent by itself) |

## 3. FORMAL_SPEC_ENGLISH (plain-English paraphrase of every claim)

- **`selectResult(L)` (the contract value).** Given the in-order list `L` of the
  `parent_link` flags of the `OneToOneField`s targeting one parent: if any flag
  is `True`, the chosen field is the **first** `True` one; else if `L` is
  non-empty, the chosen field is the **last** one; else none is chosen (`0`).
- **`(SELECT)`.** Running the loop from a fresh start (`chosen=0, cpl=False,
  j=1`) over `L0` terminates with `chosen = selectResult(L0)`, `cpl =
  containsTrue(L0)`, and the counter advanced to `1+lenB(L0)`.
- **`(LOOP)` (circularity).** Resumed mid-loop with an arbitrary already-chosen
  field `C` (flag `P`), counter `J≥1`, and remaining flags `L`: once an explicit
  parent link is locked (`C≠0 ∧ P`) it is never overwritten; otherwise the loop
  ends on the first `True` in `L` (if any) else the last element of `L`. Final
  `cpl` is `True` iff an explicit parent link was seen.
- **`(CASE-A)`** `L0 = [True, False]` (`document_ptr` then `origin`) ⇒ `chosen=1`:
  `document_ptr` wins.
- **`(CASE-B)`** `L0 = [False, True]` (`origin` then `document_ptr`) ⇒ `chosen=2`:
  `document_ptr` **still** wins — winner is order-independent.
- **`(CASE-LONE)`** `L0 = [False]` ⇒ `chosen=1, cpl=False`: the lone unmarked
  field is still selected, so the consumer raises `Add parent_link=True`.

## 4. SPEC_AUDIT (formal-English vs INTENT_SPEC)

| Intent | Formal claim(s) | Verdict |
|--------|-----------------|---------|
| I1 winner = explicit `parent_link`, order-independent | `(SELECT)` `containsTrue ⇒ firstTrue`; `(CASE-A)`=1 & `(CASE-B)`=2 (both pick the marked field) | **pass** — winner is the marked field in either order |
| I2 unmarked selected ⇒ error (no silent auto-create) | `(CASE-LONE)` selects the field (`chosen=1`), so `_prepare()` error fires; `selectResult` never returns `0` for a non-empty list | **pass** (positive evidence E6/E7) |
| I3 no field ⇒ auto `…_ptr` | `selectResult(.BList)=0` ⇒ key absent ⇒ `base.py:250` auto-creates | **pass** |
| I4 preserve all valid configs | `selectResult` = legacy "last wins" whenever `containsTrue(L)` is false; differs only by promoting a marked field over an unmarked one | **pass** — change is confined to the ambiguous case |
| I5 parent link == pk | consumer `_prepare()` promotes `parents[parent]` to pk; V1 makes that the marked field | **pass** |
| E5 "lone case is a bug" | deliberately **not** encoded as no-error | **resolved/SUSPECT** — see F1; rejected on positive doc intent (E6), with side-by-side derivation in PROOF.md |

No `fail`. One `SUSPECT` (E5) resolved against documentation, with the rejected
alternative promoted to a tested hypothesis (F-ALT) rather than dropped on scope.

## 5. PUBLIC_COMPATIBILITY_AUDIT

V1 changes only the body of the private `parent_links` collection loop inside
`ModelBase.__new__`. Audit of public surface:

- **No signature/return/dispatch change.** No public method signature, return
  type, or virtual-dispatch call is altered. `ModelBase.__new__` keeps its
  contract; `Options._prepare()` is untouched.
- **`_meta.parents` shape unchanged.** Still `{parent_model: parent_link_field}`;
  only *which* field is stored in the multiple-reference case changes (now the
  `parent_link=True` field). Consumers (`get_ancestor_link`,
  `_meta.get_parent_list`, `Collector`, the `_set_pk_val` loop at
  `base.py:581`) read a field object and are agnostic to which OTO it is.
- **Backward compatibility.** For every configuration that previously *worked*,
  the selected field is identical (those had at most one OTO to the parent, or
  the marked field already declared last). Configurations that previously
  *raised* `ImproperlyConfigured` for a multiply-referenced parent now succeed —
  an error→success transition, which is compatible.
- **Callsites/overrides:** none require changes. No new keyword is passed to any
  overridable method. **Status: clean.**

## 6. Modelling-soundness note (why one symbolic per-key list suffices)

`parent_links` is keyed by target model; the loop body for one key never reads or
writes another key's entry. Hence the global loop is the independent product of
per-key folds, and proving the contract for one symbolic in-order flag list `L`
(the sub-sequence of OTOs targeting that key, across
`reversed([new_class] + parents) × local_fields`) proves it for every key. A
field is modelled by (`parent_link` flag, position); positions are distinct so
position = identity. Provenance: from_code (E10); this is a faithful abstraction,
not an intent claim.
