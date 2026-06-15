# ITERATION_GUIDANCE.md — next-pass guidance

Outcome of this FVK pass: **V1 stands unchanged.** The audit confirmed the fix
against the full public intent and falsified the one named alternative. Below is
the actionable feedback a next code/spec/intent iteration should carry.

## Verdict and why no code change

- The constructed proof discharges every MUST obligation O1–O3, O5, O5b, O6, O7
  ([`PROOF.md`](PROOF.md) §3–§7); O4/O5c hold.
- The single adequacy question — should a *lone unmarked* `OneToOneField` to the
  parent keep raising `Add parent_link=True`? — was resolved **for** V1's behavior
  by positive documentation evidence (E6/E7) and the consumer error, after
  promoting the contrary thread comment (E5) and the "filter" patch (F-ALT) to
  tested hypotheses and **falsifying** the patch against O2 (PROOF §7).
- No code edit is justified: the change-confinement proof (O5) shows V1 differs
  from the original *only* in the exact multiple-reference ambiguity the issue
  reports. Editing further would either regress O2 (the filter patch) or
  introduce an untested cross-base regression (the community sort+first-wins
  patch — see below).

## UltimatePowers-style clarification questions (for the human/intent layer)

1. **Lone unmarked OTO to the parent** — should it (a) keep raising
   `Add parent_link=True` *(V1, matches docs E6 & `test_missing_parent_link`)*,
   or (b) be treated as a regular field with an auto-created `…_ptr`? V1 assumes
   (a). If product intent is actually (b), that is a **separate** deprecation
   change, needs its own release note + test update, and would make the
   `options.py` "Add parent_link=True" error dead code.
2. **Two `parent_link=True` fields to one parent** (F3) — error, first-wins, or
   last-wins? Currently undefined; V1 = first-wins. Worth a system check if it
   recurs.

## Recommended next code/spec changes

- **None required** for this issue. If question 1 is ever answered (b), implement
  it deliberately (filter + remove the `_prepare` error + update docs/tests),
  *not* as a side effect of this fix.
- **Optional hardening (out of scope, no public-intent evidence yet):** a
  `models.E…` system check for "multiple `parent_link=True` to the same parent"
  (F3). Do **not** add without intent evidence.

## Alternatives considered and rejected (carry-forward so a regenerator doesn't
re-introduce them)

- **A-filter** (`… and field.remote_field.parent_link`): the literal reading of
  hint E3. **Rejected — fails O2** (silently drops the lone-OTO error; breaks
  `test_missing_parent_link`). PROOF §7.
- **A-sort-first-wins** (community PR in the issue: sort `parent_link`-first +
  `if related_key not in parent_links`): fixes the reported single-class case but,
  with the `reversed([new_class] + parents)` order, becomes "first base wins,"
  which lets a plain OTO on an abstract base shadow a `parent_link` on the child
  (cross-base scenario X regresses vs. the original). **Rejected** — V1's
  "never overwrite a stored `parent_link`" guard handles X and Y correctly
  (PROOF §4). Do not regenerate to this form.
- **A-within-base-sort** (sort each base's fields, keep last-wins): fixes the
  reported case with zero cross-base change but leaves scenario Y wrong (abstract
  `parent_link` overwritten by a child plain OTO). V1 is strictly more correct.

## Tests

- **Keep** `test_missing_parent_link` (O2 boundary) and `test_abstract_parent_link`
  (O5b) — unconditionally; they guard exactly the obligations this audit relies on.
- **Add** (if not already in the hidden suite) a multiple-OTO MTI test asserting
  the `parent_link=True` field is `_meta.parents[parent]` / the pk in **both**
  declaration orders — the FAIL→PASS for this issue (`(CASE-A)`/`(CASE-B)`).
- No removals recommended (proof constructed, not machine-checked; all candidate
  tests also exercise real metaclass/`_prepare` wiring).

## To machine-check (upgrades "constructed" → "verified")

Run the §8 commands in [`PROOF.md`](PROOF.md) (`kompile` → `kprove`, expect
`#Top`). Only then act on any test-redundancy recommendation.
