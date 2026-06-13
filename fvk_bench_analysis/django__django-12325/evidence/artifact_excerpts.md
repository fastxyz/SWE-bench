# Key FVK artifact excerpts — the root cause is STATED, then reasoned against

All paths under `results/batch1-XC-MINI-PRO-AHP/django__django-12325/`.

## Inventory
`fvk/`: `SPEC.md` (123 L), `FINDINGS.md` (174 L), `PROOF_OBLIGATIONS.md` (86 L),
`PROOF.md` (187 L), `ITERATION_GUIDANCE.md` (89 L), `mti_parent_links.k` (101 L),
`mti_parent_links-spec.k` (97 L). Plus `reports/fvk_notes.md` (135 L).
Two `.k` files present. Nothing missing.

## Scope = the CORRECT region (not a wrong-scope case)

`fvk/SPEC.md:3-5`
```
**Target:** `repo/django/db/models/base.py`, `ModelBase.__new__`, the
`parent_links` collection loop (lines 194–219, as modified by the V1 fix).
```
This is exactly the region the oracle patch modifies (`base.py` @ line ~204). FVK
also traced the `options.py` consumer that raises the error:

`fvk/SPEC.md:103-104`
```
- **`Options._prepare`** (options.py:241–257): promotes the parent link to the
  primary key and raises `ImproperlyConfigured` if it is not `parent_link=True`.
  I2 ⇒ the parent-link field is chosen ⇒ **no spurious error**.
```

## THE SMOKING GUN — the oracle's exact fix is quoted and explicitly rejected

`fvk/FINDINGS.md:78-84` (Finding F-4)
```
This finding is why the fix must **not** be the tempting one-liner "only record
`parent_link=True` fields" (`if isinstance(field, OneToOneField) and
field.remote_field.parent_link`). That variant would drop the lone non-parent
OTO from `parent_links`, silently auto-create `place_ptr`, and **break this
test**. The V1 guard deliberately keeps non-parent-link fields as the fallback
```

`fvk/ITERATION_GUIDANCE.md:23-31` (G-1)
```
- **Evidence:** F-4 / PO-12. The tempting one-liner
  `if isinstance(field, OneToOneField) and field.remote_field.parent_link:`
  drops lone non-parent-link OTOs from `parent_links`, which **breaks**
  `test_missing_parent_link` ...
- **UltimatePowers question:** "Is the `Add parent_link=True` error on a lone
  non-parent OTO an intended part of the public contract?" → Yes (it has a
  dedicated test). So the fallback-to-last behaviour (I3) is **required**.
```

`reports/fvk_notes.md:58-71` (Decision 2) — same rejection, "V1's shape is the
*correct* one."

→ The oracle change is named **verbatim**. FVK's only error is the premise that
`test_missing_parent_link` is an authoritative contract — but the gold patch DELETES
that test and asserts the opposite (see `failing_tests.md`,
`public_data_reachability.md`).

## The bug-preserving behavior, encoded as a proved invariant (I3)

`fvk/SPEC.md:84-87`
```
- **(I3) legacy fall-back.** If *no* candidate for `K` is `parent_link=True`,
  `parent_links[K]` is the **last** candidate in `C_K` — exactly the pre-fix
  "last write wins" behaviour, which preserves `test_missing_parent_link`.
```
`mti_parent_links-spec.k:88-89` states I3 formally in the `(SELECT-PL)` claim's
`ensures`. This is the precise formal encoding of the behavior the oracle removes.

## The decisive single-OTO case, mis-classified as correct

`fvk/FINDINGS.md:65-77` (Finding F-4 input) models the exact failing scenario
(`ParkingLot(Place)` with one plain OTO) and concludes the `ImproperlyConfigured`
raise "must still fire" — the OPPOSITE of the gold test `test_onetoone_with_parent_model`.

## Honesty hedge inverted into false confidence

`fvk/FINDINGS.md:150-156` (F-9)
```
## F-9 [SPEC-DIFFICULTY = none] A clean spec exists
... the postcondition is a clean, total biconditional (**I2**) ... The clean spec
is positive evidence the V1 fix is well-formed and complete for the issue.
```
`fvk/FINDINGS.md:171` — "the audit produced **no finding that requires changing V1**."
"Clean/total/complete" here is false reassurance: the spec was clean because FVK
defined the lone-OTO behavior (I3) as intended rather than as the defect it is.

## V1 vs final — identical (FVK only confirmed)

`md5sum` of `solutions/solution_baseline.patch`, `solution_fvk.patch`,
`solution_control.patch` are all `0aa79605b945ac451d9f2fbdc50f02b5`. The patch
touches only `base.py` (adds a `continue` guard); it does NOT touch `options.py`.
FVK changed nothing ("V1 stands unchanged", `ITERATION_GUIDANCE.md:9`).

## What FVK MISSED that the oracle does

The oracle's SECOND hunk — deleting
`if not field.remote_field.parent_link: raise ImproperlyConfigured(...)` in
`options.py:251-255` (and its import) — is never proposed. FVK *read* this raise
(SPEC §5) and treated it as a contract to satisfy, not a defect to remove.
