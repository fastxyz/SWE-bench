# Key fvk-artifact + transcript excerpts — the wrong decision (round 2)

The round-2 hardened materials closed the round-1 hole (test-as-oracle): the agent
DID mark `test_missing_parent_link` SUSPECT and DID promote the gold filter to a
tested hypothesis. It then escaped through a NEW hole: it re-grounded the same wrong
conclusion on a **documentation misreading**, manufacturing a MUST-hold obligation
(O2) that enshrines the exact behavior the gold patch removes.

## A. The decision moment (transcript, fvk session forked from baseline)

`transcripts/fvk.jsonl.gz` — assistant text. The pivotal reasoning happened in the
baseline turns that fvk forked and then ratified:

> **[line 32]** "The docs (`releases/1.10.txt:1170-1171`, `internals/deprecation.txt:318-319`)
> confirm the design: implicit promotion of a `OneToOneField` to a `parent_link` was
> **deprecated** — Django requires an explicit `parent_link=True`, and a lone
> OneToOneField to the parent without it should still error
> (`test_missing_parent_link`). So the fix must **not** silently auto-create the ptr
> (my current `and field.remote_field.parent_link` edit would break that)."

> **[line 43]** "The removal of 'implicit promotion' means: an unmarked OneToOneField
> that Django selects as the parent link must raise an error
> (`test_missing_parent_link`) — it is **not** silently ignored. So my current
> `and field.remote_field.parent_link` edit is **wrong** (it would make that error
> unreachable and silently auto-create the ptr)."

> **[line 45]** "The correct, targeted fix: keep collecting all OneToOneFields, but
> never let a regular OneToOneField overwrite the one explicitly marked
> `parent_link=True`."

=> The agent HELD the gold base.py one-liner ("my current edit"), then reverted it
on the strength of the deprecation note. It never proposed gold HUNK 2 (delete the
options.py raise) because the same reading made that raise *required*.

## B. The exact doc the agent read (tool_result in transcript) — and why the reading is wrong

`repo/docs/releases/1.10.txt:1170-1171`:
> "In multi-table inheritance, implicit promotion of a `OneToOneField` to a
>  `parent_link` is deprecated. Add `parent_link=True` to such fields."

`repo/docs/internals/deprecation.txt:318-319`:
> "In multi-table inheritance, implicit promotion of a `OneToOneField` to a
>  `parent_link` will be removed."

**Correct reading:** old Django would *silently treat* a plain pk OTO to the parent
AS the parent link (implicit promotion). That silent promotion is deprecated: if you
WANT that field to be the link, mark it `parent_link=True`.
**The agent's reading (wrong):** "a plain OTO to the parent must RAISE." It conflated
"stop silently promoting it (to the parent link)" with "reject it (ImproperlyConfigured)."
Post-deprecation, a plain OTO is simply an ordinary field and Django auto-creates a
SEPARATE `*_ptr` — which is exactly what gold's `test_onetoone_with_parent_model`
(`check()==[]`) asserts.

## C. The public hint the agent had that DIRECTLY contradicts its reading

Problem `hints_text` (ledger E5), verbatim:
> "Been able to replicate this bug with a simpler case: class Picking(Document):
>  some_unrelated_document = models.OneToOneField(Document, ...) **Produces the same
>  error** against some_unrelated_document."

and:
> "Having pk OneToOne with to MTI child **should imply it's parent link**." (i.e. the
> marker should NOT be mandatory; the lone-OTO error is wrong.)

The maintainers call the lone-OTO `ImproperlyConfigured` "the same **bug**." The agent
quoted this as E5, marked it SUSPECT (correctly, per the new rule), then **overrode it
with E6** — siding with its misreading of the deprecation doc over the issue's explicit
statement that this very error is the bug.

## D. Where the inverted obligation is enshrined (the smoking gun in the formal layer)

`fvk/PROOF_OBLIGATIONS.md` O2 (marked **"MUST hold"**):
> "**O2 — lone / unmarked selection still errors (no silent auto-create).** Source:
>  E6, E7, E8 (I2). Statement: for a non-empty L with containsTrue(L)=false,
>  selectResult(L)=lenB(L) >= 1 != 0, i.e. a field is still selected, so
>  `Options._prepare()` raises `Add parent_link=True`. ... **MUST hold.**
>  (This is the obligation that rejects the alternative 'filter to parent_link only'
>  patch — see F-ALT / O6.)"

`fvk/SPEC.md` I2:
> "Implicit promotion of an unmarked `OneToOneField` was deprecated and removed — an
>  unmarked field selected as the parent link **must raise** `ImproperlyConfigured:
>  Add parent_link=True to <field>`."

`fvk/PROOF.md` §7 (the side-by-side falsification of the gold fix):
> "| `[false]` (lone, E8) | `1` => `_prepare` **raises** Add parent_link=True | `0`
>  => key absent => **auto-creates `…_ptr`, no error** | **O2/E6** — V1 ✓, **Alt ✗** |
>  ... Therefore the alternative **fails a public obligation (O2)**; V1's choice is
>  *forced*, not merely preferred."

This is the round-1 STATED pattern (primer §v.8): the artifacts name gold's exact fix
(`isinstance(field, OneToOneField) and field.remote_field.parent_link`, ledger E3 /
F-ALT) and then reject it — but in round 2 the rejection is dressed as a
docs-grounded "forced" obligation (O2) rather than bare test-deference. The
side-by-side derivation the new guidance demanded was *performed* — but its "public
obligation" O2 is itself the inverted (wrong) requirement, so the derivation
faithfully reaches the wrong end-state.

## E. fvk_notes.md — the agent narrates following the new rules while landing wrong

`reports/fvk_notes.md` Decision 2:
> "A thread comment (ledger E5) calls the lone-`OneToOneField` error 'the same bug,'
>  which made `test_missing_parent_link` (E8) a SUSPECT obligation — I was not allowed
>  to keep it merely because it exists. I therefore re-derived the lone case from
>  positive intent: the Django **docs** (E6 ... 'removed' in 2.0; E7) and the live
>  `options.py` error positively require that an unmarked selected field raise
>  `Add parent_link=True`. So the behavior is documented intent, not legacy inertia,
>  and V1 correctly preserves it (O2, finding F1)."

Decision 3:
> "the literal reading of hint E3 ... promoted ... to a tested hypothesis ... on a
>  lone unmarked field, returns 'no selection' => the `Add parent_link=True` error
>  becomes unreachable ... it **fails O2/E6** ... Hence V1's *priority-not-filter*
>  design is forced, not merely preferred."

The agent explicitly cites the hardened rules (SUSPECT-resolution duty in
`intent-evidence.md` §1; "named change must not be dropped on scope grounds") and
follows their LETTER — but the "positive intent" it substitutes for the test is a
misread doc, so the SUSPECT override and the "forced" verdict both point the wrong way.
