# FINDINGS — parent-link collection loop (V1 audit)

Plain-language findings from formalizing the V1 fix in
`repo/django/db/models/base.py` (`ModelBase.__new__`, lines 194–219). Format:
`input → observed vs expected`. Findings are non-blocking advice; none of them,
on audit, requires a V1 code change (see `reports/fvk_notes.md` for the
trace-through and the "V1 stands" decision).

Legend: **[FIXED-BY-V1]** the bug the fix targets; **[POSITIVE]** the spec is
satisfied / a guard enforces a precondition; **[OUT-OF-SCOPE]** real but
pre-existing and outside this issue; **[PROOF-DERIVED]** surfaced by `/verify`.

---

## F-1 [POSITIVE] No `AttributeError` from the new attribute reads — PO-1/PO-2

> input: any candidate field reaching the body.
> observed: `existing = parent_links.get(related_key)` is `None` or a
> previously-stored `OneToOneField`; the new conjunct
> `existing.remote_field.parent_link` is read **only after**
> `existing is not None` (Python `and` short-circuits), and `existing` is always
> a `OneToOneField`, which always has `remote_field.parent_link`.
> expected: no crash. **Holds.**

The V1 guard introduced two attribute reads (`existing.remote_field.parent_link`,
`field.remote_field.parent_link`). Formalizing forced PO-1/PO-2: the reads are
total on the domain. `parent_links` only ever holds values written under the
`isinstance(field, OneToOneField)` branch, and `OneToOneField.remote_field`
(a `OneToOneRel`) always carries `parent_link` (default `False`) — confirmed in
`repo/django/db/models/fields/related.py:461-470`. No precondition is missing.

## F-2 [FIXED-BY-V1] Declaration order changed which OTO became the parent link

> input:
> ```python
> class Picking(Document):
>     document_ptr = OneToOneField(Document, parent_link=True, related_name='+', on_delete=CASCADE)
>     origin       = OneToOneField(Document, related_name='picking', on_delete=PROTECT)
> ```
> observed (pre-fix): the unconditional `parent_links[key] = field` let the
> last-declared OTO win, so `parent_links[Document] = origin`; `Options._prepare`
> then raised `ImproperlyConfigured: Add parent_link=True to …Picking.origin`.
> Swapping the two field lines "fixed" it by accident.
> expected: the `parent_link=True` field (`document_ptr`) is chosen for either
> order. **V1 satisfies this** via postcondition **I2** (parent-link priority,
> order-independent); see `fvk/SPEC.md §4` and the `(SELECT-PL)` proof.

This is the root cause and the reason the fix exists. The corollary
(`fvk/SPEC.md §4`) is the precise "order must not matter" guarantee the reporter
asked for.

## F-3 [POSITIVE] Domain (key set) of `parent_links` is unchanged — PO-12/PO-13

> input: any model.
> observed: V1 inserts a key on the *first* candidate for that key (empty slot ⇒
> the guard's `existing is not None` is false ⇒ assignment runs), and never
> removes keys. So `keys(parent_links)` equals the pre-fix code's exactly.
> expected: the fix must not change *which* parents are linked, only *which
> field* links a given parent. **Holds.**

This is the obligation that keeps `invalid_models_tests…test_missing_parent_link`
green (next finding) and guarantees no model that used to auto-create a `*_ptr`
suddenly stops, or vice versa.

## F-4 [POSITIVE] `test_missing_parent_link` contract is preserved — I3

> input:
> ```python
> class ParkingLot(Place):
>     parent = OneToOneField(Place, on_delete=CASCADE)   # NOT parent_link
> ```
> observed: single non-parent-link candidate ⇒ by **I3** `parent_links[Place] =
> parent` (last = only) ⇒ `Options._prepare` raises
> `Add parent_link=True to …ParkingLot.parent`. Identical to pre-fix.
> expected: the documented "you must mark the parent link" error must still fire.
> **Holds.**

This finding is why the fix must **not** be the tempting one-liner "only record
`parent_link=True` fields" (`if isinstance(field, OneToOneField) and
field.remote_field.parent_link`). That variant would drop the lone non-parent
OTO from `parent_links`, silently auto-create `place_ptr`, and **break this
test**. The V1 guard deliberately keeps non-parent-link fields as the fallback —
see `reports/baseline_notes.md` "rejected alternatives" and
`fvk/ITERATION_GUIDANCE.md`.

## F-5 [POSITIVE / guard-as-precondition] The `isinstance(.., OneToOneField)` filter

> input: a plain `ForeignKey`/`AutoField`/concrete field on the child (e.g.
> `ParkingLot.main_site = ForeignKey(Place, related_name='lot')`).
> observed: excluded from candidacy; never considered a parent link.
> expected: only `OneToOneField`s can be MTI parent links. The guard **enforces**
> the spec precondition (modelled as: `VS` contains only `field(..)` candidates).
> **Holds.** This is a guard-enforces-precondition positive, per
> `formalize.md` step 5.

## F-6 [PROOF-DERIVED, OUT-OF-SCOPE] Two non-parent-link OTOs to the same parent

> input:
> ```python
> class Picking(Document):
>     a = OneToOneField(Document, related_name='a', on_delete=PROTECT)
>     b = OneToOneField(Document, related_name='b', on_delete=PROTECT)
> ```
> observed: by **I3**, `parent_links[Document] = b` (last); `Options._prepare`
> raises `Add parent_link=True to …Picking.b`. The error names `b`, not `a`.
> expected: an error *is* appropriate (no parent link declared); *which* field it
> names is cosmetic and order-dependent.

This is **pre-existing** behaviour (the original code also picked the last) and
**outside** this issue, which is specifically about a parent-link field losing to
a non-parent-link field. Not changed by V1; no fix warranted. Recorded only so
the audit is complete. UltimatePowers question for a future pass: "when no
parent link is declared but multiple OTOs to the parent exist, should the error
enumerate *all* candidates rather than name the last?"

## F-7 [PROOF-DERIVED, OUT-OF-SCOPE] Two *parent_link=True* OTOs to the same parent

> input: two distinct `OneToOneField(Parent, parent_link=True, …)` to the same
> parent on one child (an invalid configuration).
> observed: by the V1 rule, the **last** parent-link candidate wins
> (`updateSel` overwrites when the incoming field is itself a parent link);
> `parent_links[Parent]` is well-defined and a parent link, so this loop does not
> error.
> expected: ideally a dedicated "multiple parent links to the same parent" model
> check. None exists in this loop today (the original code also silently picked
> one). I2/I1 still hold (chosen ∈ candidates, is a parent link).

**Pre-existing and out-of-scope.** V1 neither introduces nor worsens this; it
keeps the original's silent last-wins. Flagged as a *possible future system
check*, not a change for this issue. See `fvk/ITERATION_GUIDANCE.md`.

## F-8 [POSITIVE, PROOF-DERIVED] Both reported symptoms collapse to one root cause

> input: the failing `Picking` above, with `primary_key=True` added to
> `document_ptr` (the hint's work-around).
> observed in the issue: the `ImproperlyConfigured` warning disappears but the
> model is "still broken (complains about `document_ptr_id` not populated) unless
> field order is correct."
> root cause: `_set_pk_val` (base.py:583-587) iterates `_meta.parents.values()`
> and writes the pk into each parent link's `target_field`; if `origin` (not
> `document_ptr`) is the recorded link, the wrong column is populated.
> expected: with **I2** selecting `document_ptr` as the link regardless of order,
> `_meta.parents[Document] = document_ptr`, and the pk propagates to
> `document_ptr_id`. **Both symptoms are resolved by the single selection fix.**

The formal audit confirms the two issue symptoms are not independent bugs:
correcting the field *selection* (this loop) fixes the `_prepare` error **and**
the `_set_pk_val` runtime population, so no second code site needs editing.

## F-9 [SPEC-DIFFICULTY = none] A clean spec exists

Per `formalize.md` step 7, an *inability* to write a clean spec is itself a bug
signal. Here the opposite holds: the postcondition is a clean, total
biconditional (**I2**) plus a fall-back (**I3**) and a domain-preservation clause
(**D**), with a one-line invariant proof. The clean spec is positive evidence the
V1 fix is well-formed and complete for the issue.

---

## Proof-derived findings from `/verify` (summary)

| Evidence | Classification | Verdict |
|---|---|---|
| PO-1/PO-2 (attribute reads total) | needed-guard check → satisfied | no change |
| `(SELECT-PL)` I2 holds for all orders | core correctness | **fix correct** |
| PO-12/PO-13 (domain preserved) | regression guard → satisfied | no change |
| I3 keeps `test_missing_parent_link` | test-contract guard → satisfied | no change |
| PO-7/PO-8/PO-11 list-induction | proof **capability** gap, not code bug | `[ESC]`, hand-proved |
| F-6 / F-7 multiple-OTO edge cases | pre-existing, out-of-scope | future check only |

**Bottom line:** the audit produced **no finding that requires changing V1**.
Every clause of the intended contract is met; the only deferral is the *machine*
check of the list-inductive VCs, which is a tooling-tier limitation, not a defect
in the fix.
