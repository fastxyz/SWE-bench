# Public-data reachability — the root cause was fully derivable, and STATED in-issue

The instance's `problem_statement` + `hints_text` (both PUBLIC, from
`fvk_bench/data/instances.json`) contain the exact fix direction and a reproducer
that V1 fails. The fvk transcript confirms the agent READ all of these.

## Signal 1 — the exact one-line oracle fix, quoted by a Django core dev in the hints

> "Not sure why we're **not checking and field.remote_field.parent_link** on parent
> links connection." — (hints_text)

This is verbatim the oracle's change to `base.py`
(`if isinstance(field, OneToOneField) and field.remote_field.parent_link`).
FVK even cites this hint in `SPEC.md §1` ("the public hint about checking
`field.remote_field.parent_link`") — then rejected acting on it (F-4 / G-1).

## Signal 2 — the simpler reproducer == the new failing test, called a BUG in the hints

> "Been able to replicate **this bug** with a simpler case:
> `class Picking(Document): some_unrelated_document = models.OneToOneField(Document,
> related_name='something', on_delete=models.PROTECT)`
> Produces the **same error** against some_unrelated_document." — (hints_text)

This is exactly `test_onetoone_with_parent_model` (one plain OTO to the parent,
no parent_link). The public discussion calls it a bug to be fixed. FVK's SPEC clause
**I3** / finding **F-4** treat the identical case as *correct, required* behavior
("the documented 'you must mark the parent link' error must still fire").

## Signal 3 — the premise FVK preserved is explicitly challenged in the issue

> "Why is parent_link even necessary in that case? Having pk OneToOne with to MTI
> child should imply it's parent link." — (hints_text)

The issue is arguing the lone/implicit case should NOT require the marker — the
opposite of the contract FVK locked in.

## Transcript confirms FVK saw all of it

`zcat transcripts/fvk.jsonl.gz | grep -ic <phrase>`:
- `some_unrelated_document` → 6 ; `simpler case` → 4 ; `same error against` → 2
- `not checking and field.remote_field.parent_link` → 2
- `Having pk OneToOne` → 4
- `test_missing_parent_link` (the PRE-FIX test FVK relied on) → 31
- `test_models.py` → 62 ; `assertRaisesMessage` → 4 ; `ParkingLot` → 16

## The fatal move

FVK read `test_missing_parent_link` **as it existed at the base commit** (i.e. before
the fix) and elevated it to "the authoritative public contract"
(`ITERATION_GUIDANCE.md` G-1: *"Is the `Add parent_link=True` error on a lone
non-parent OTO an intended part of the public contract? → Yes (it has a dedicated
test). So the fallback-to-last behaviour (I3) is required."*). It therefore rejected
the very fix the issue/hints requested. The pre-fix test was used as **false
reassurance** to confirm an incomplete V1 — the same failure-shape flagged in
primer §v(7), but here on the *right* region with the *right* fix explicitly in hand.

Conclusion: **fully reachable from public data**; not a hidden-test-only signal.
