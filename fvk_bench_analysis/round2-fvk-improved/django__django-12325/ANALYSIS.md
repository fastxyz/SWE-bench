# Analysis — `django__django-12325` (FVK arm, ROUND 2 · run `fvk-improved-4cases-XC-MINI-PRO-AHP`)

**ROUND-2 OUTCOME: still FAILS (fvk `resolved:false`, FTP 0/2).** **Failure class:
PARTIAL (both gold hunks absent) driven by an INVERTED adequacy obligation.**
**Closable by materials: PARTIAL** (the round-2 hardening helped *procedurally* but
not *materially*; the residual gap is a domain misreading, not a methodology hole).

The round-1 verdict was **STATED**: fvk localized the exact fix, quoted gold's
one-liner, then argued itself out of it on the authority of a pre-fix in-repo test
the gold patch deletes. Round 2 hardened the materials (`intent-evidence.md` §1
SUSPECT rule; `verify.md` "forced ⇒ falsify side-by-side", "a named change must not
be dropped on scope grounds"). The agent **followed those rules to the letter** — it
marked `test_missing_parent_link` SUSPECT, promoted gold's filter to a tested
hypothesis, and ran the side-by-side derivation — and **still produced V1 unchanged**.
It escaped the patched hole through a new one: it re-grounded the *same* wrong
conclusion on a **misreading of Django's 1.10 deprecation note**, manufacturing a
MUST-hold proof obligation (**O2**) that enshrines the very behavior the gold patch
removes. The information needed to flip remained fully present and was again reasoned
against.

> **Note on the run framing.** `solution_fvk.patch` is **byte-identical** to
> `solution_baseline.patch` (md5 `be7054997c4b33c6508c6d10a266941b`;
> `diff` => no output). The "22-line patch" is 22 lines *of patch file* (11 added /
> 2 removed, `base.py` only). So for THIS instance the round-2 fvk arm did **not**
> act differently from baseline — it CONFIRMED V1 ("V1 stands unchanged",
> `fvk/ITERATION_GUIDANCE.md:3`). The sibling pytest-10356 flip did not transfer here.

---

## 1. Root cause (gold) — restated crisply, BOTH hunks

**Bug:** In multi-table inheritance, the parent-link collector treats *every*
`OneToOneField` to the parent as a candidate parent link. This (a) makes the
last-declared OTO overwrite earlier ones (declaration order decides the outcome), and
(b) makes even a *single plain* OTO to the parent wrongly raise
`ImproperlyConfigured: Add parent_link=True to ...`, instead of being treated as an
ordinary field beside an auto-created `*_ptr`.

**Location & fix (two hunks, both required — `evidence/oracle_patch_excerpt.diff`):**

1. `django/db/models/base.py`, `ModelBase.__new__`, the `parent_links` loop (~L204):
   ```diff
   -                if isinstance(field, OneToOneField):
   +                if isinstance(field, OneToOneField) and field.remote_field.parent_link:
                        related = resolve_relation(new_class, field.remote_field.model)
                        parent_links[make_model_tuple(related)] = field
   ```
   Record **only** fields explicitly flagged `parent_link=True`.

2. `django/db/models/options.py`, `Options._prepare` (~L251) — **delete** the guard
   (and the now-unused import):
   ```diff
                    field.primary_key = True
                    self.setup_pk(field)
   -                if not field.remote_field.parent_link:
   -                    raise ImproperlyConfigured('Add parent_link=True to %s.' % field,)
   ```

**Net effect:** a lone plain OTO to the parent is no longer recorded as a parent link
(HUNK 1), so Django auto-creates a separate `*_ptr`; and the lone-OTO error is gone
(HUNK 2) — a lone plain OTO is now **valid**. Order no longer matters.

**Bug TYPE:** wrong / under-specified condition (a **missing predicate** in a
dispatch) coupled with a **misplaced precondition check** (the `ImproperlyConfigured`
raise) that fires on valid input.

**FAIL_TO_PASS (`eval/fvk.report.json`):** `test_clash_parent_link` and
`test_onetoone_with_parent_model`. The gold test patch **deletes the pre-fix
`test_missing_parent_link`** (lone OTO ⇒ must raise) and replaces it with
`test_onetoone_with_parent_model` asserting the **opposite** (lone plain OTO ⇒
`check() == []`, valid). See `evidence/failing_ftp_tests.md`.

**Public-data reachability: YES, strongly.** The public `hints_text` calls the
lone-OTO error "the same **bug**", supplies the exact `some_unrelated_document`
reproducer, quotes the `field.remote_field.parent_link` hint, and argues "Having pk
OneToOne ... **should imply it's parent link**" (i.e. the marker should not be
mandatory). All of gold's direction is in the public issue.

---

## 2. What the NEW fvk arm did (new V1 = new fvk patch; precise gap vs gold)

**New V1 (= baseline = fvk, byte-identical).** `base.py` ONLY; keeps the broad
`isinstance(field, OneToOneField)` predicate and still records plain OTOs, adding a
"never overwrite an already-stored `parent_link` field" guard
(`evidence/new_fvk_patch.diff`):

```python
related_key = make_model_tuple(related)
existing = parent_links.get(related_key)
if existing is not None and existing.remote_field.parent_link:
    continue
parent_links[related_key] = field
```

This makes the *multiple-OTO* winner order-independent (the marked field is never
clobbered) — it fixes the issue's headline `Picking` case. But it does **nothing** for
the *lone plain OTO* case: with no existing parent_link to protect, the `continue`
never fires, so the plain field is still recorded and still hits the un-removed
`options.py` raise.

**Precise gap vs gold — BOTH hunks absent; one actively contradicted:**

- **Gold HUNK 1 (base.py predicate):** NOT done. fvk explicitly considered it (ledger
  **E3**, alternative **F-ALT**), promoted it to a tested hypothesis, and **rejected**
  it. Gold quote vs what fvk wrote:
  - gold: `if isinstance(field, OneToOneField) and field.remote_field.parent_link:`
  - fvk: `if isinstance(field, OneToOneField):` (unchanged) + the `existing ...
    continue` guard.
- **Gold HUNK 2 (delete the options.py raise):** NOT done — `options.py` is never
  touched. Worse, fvk **certifies** that raise as a required behavior (SPEC **I2**,
  obligation **O2** "MUST hold"; `fvk/SPEC.md:28-29`, `fvk/PROOF_OBLIGATIONS.md:16-22`).

Right file, right method, right region — wrong direction. This is **PARTIAL**, not
WRONG-LOCATION: V1 even reads and reasons about the exact `options.py` raise
(`fvk/SPEC.md:99` / PROOF §6) but classifies it as a contract to *satisfy*, not a
defect to *remove*. No PASS_TO_PASS regression (PTP all green), so it is not
OVER-REACH either.

**Key artifacts** (all present; two `.k` files `mini-python.k`,
`parent-links-spec.k`): `SPEC.md` (intent ledger E1–E10, intent clauses I1–I5, formal
`selectResult`); `FINDINGS.md` (C1/C2 confirm the multiple-OTO fix; **F1** upholds the
lone-OTO error; **F-ALT** falsifies the gold filter); `PROOF_OBLIGATIONS.md` (O1–O7,
the inverted **O2** the whole rejection turns on); `PROOF.md` §7 (the two-column
falsification of gold); `ITERATION_GUIDANCE.md` (Q1 frames the gold direction as a
"*separate* deprecation change"); `reports/fvk_notes.md` (Decisions 1–3).

---

## 3. Diagnosis (the heart) — WHY the fvk patch fails the 2 FTP tests

**Mechanical why (`evidence/failing_ftp_tests.md`):** `test_onetoone_with_parent_model`
declares a lone plain `other_place = OneToOneField(Place)`. Under V1, `other_place` is
recorded as the parent link; `Options._prepare` reaches the un-removed
`if not field.remote_field.parent_link: raise ImproperlyConfigured('Add parent_link=True
to ...other_place')` ⇒ `check()` returns a non-empty list ⇒ FAIL. Gold excludes
`other_place` from `parent_links` (HUNK 1) and deleted the raise (HUNK 2) ⇒ `check()==[]`.

**Where the reasoning diverged from gold — and did the new guidance help?**

The round-2 hardening **helped partially**: it stopped fvk from deferring to the
deleted test *on the test's bare authority*. fvk correctly marked
`test_missing_parent_link` **SUSPECT** (`intent-evidence.md` §1) and correctly
promoted gold's filter to a tested hypothesis rather than dropping it on scope
(`verify.md` line 62). The round-1 hole is genuinely closed: the agent **acted on**
the methodology.

But it then escaped through a **new hole**: it substituted a **misread documentation
clause** for the rejected test and reached the identical wrong conclusion. The pivot
(transcript `[lines 32/43/45]`, `evidence/decision_excerpts.md` A/B):

> [line 43] "The removal of 'implicit promotion' means: an unmarked OneToOneField that
> Django selects as the parent link must raise an error ... So my current `and
> field.remote_field.parent_link` edit is **wrong**."

The 1.10 note it read (`docs/releases/1.10.txt:1170-1171`, ledger **E6**) says only:
*"implicit promotion of a `OneToOneField` to a `parent_link` is deprecated. Add
`parent_link=True` to such fields."* The **correct** reading: old Django silently
*treated* a plain pk OTO to the parent **as** the parent link; that silent promotion
is deprecated, so mark the field if you want it to be the link. The **agent's** reading
conflated "stop silently **promoting** it (to parent link)" with "**reject** it
(`ImproperlyConfigured`)." Post-deprecation, a plain OTO is simply an ordinary field
and Django auto-creates a *separate* `*_ptr` — exactly what the gold test asserts. The
agent inverted the deprecation's meaning.

That inversion is then **laundered into the formal layer** as obligation **O2**
("lone / unmarked selection still errors", *MUST hold*,
`fvk/PROOF_OBLIGATIONS.md:16-22`) and intent **I2** (`fvk/SPEC.md:28-29`). The
side-by-side derivation the new rule demanded (`PROOF.md` §7) was *performed
correctly* — but its "public obligation" O2 is the inverted requirement, so the
derivation faithfully concludes the gold filter "**fails O2**" and V1 is "**forced**".
The methodology's `verify.md:56` test ("keep 'forced' only if the alternative
demonstrably fails a *public obligation*") was satisfied on paper because O2 *looks*
like a public obligation (it cites docs E6/E7 and test E8) — but O2 is **false**.

Critically, fvk had the public statement that this exact error is the bug: ledger
**E5** quotes the issue's "*Produces the **same error*** ... simpler case", and the
hint "Having pk OneToOne ... **should imply it's parent link**." fvk marked E5 SUSPECT
(right) and then **overrode it with its misread E6** (wrong) — siding with a misread
doc over the issue's explicit bug report. Per `intent-evidence.md` §1's own
contrapositive ("if the issue reports current behavior X as the bug, any test or
'before' display encoding X is SUSPECT ... a test you would have to delete to satisfy
the public intent is itself a positive bug signal"), E5 should have *won*; the agent
let a doc clause it misunderstood neutralize that signal.

**Classification: PARTIAL (both gold hunks missing), via an INVERTED adequacy
obligation (O2).** This is the primer §v.8 **STATED-but-reasoned-against** pattern
persisting into round 2 — the artifacts name gold's exact fix (E3 / F-ALT) and reject
it — but the rejection has *migrated* from "binding pre-fix test" (round 1) to
"docs-grounded MUST-hold obligation" (round 2). The single most load-bearing wrong
artifact is **O2** (`fvk/PROOF_OBLIGATIONS.md:16-22`); the single most load-bearing
wrong *reasoning step* is transcript **[line 43]**.

---

## 4. How FVK materials could close the gap (round-3 recommendation)

**Headroom: PARTIAL.** The remaining failure is not a missing methodology rule — fvk
ran every relevant round-2 rule. It is a **domain misreading** (the meaning of
"deprecate implicit promotion") promoted into a "public obligation" that the
side-by-side gate then trusts. So a round-3 *material* change can plausibly help, but
only by hardening **how an obligation earns 'public' status**, not by adding yet
another "don't defer to tests" rule. Concrete, general, no-exec changes:

1. **`intent-evidence.md` / `verify.md` — a doc/spec clause that the issue calls a
   bug cannot be re-imported as a MUST obligation.** Extend the §1 SUSPECT
   contrapositive from *tests/displays* to *any current-behavior source, including
   docs and the live error string itself*: if the issue names behavior X as the bug
   (here: the lone-OTO `ImproperlyConfigured`), then a `requires`/postcondition/
   obligation that *mandates* X is SUSPECT and may not be marked "MUST hold" or used
   to falsify a named alternative — even when a doc sentence appears to support X. The
   doc may describe the *pre-fix world*; the issue is the more recent intent signal.
   (Directly targets O2/I2: built from E6/E8 to require the behavior E5 calls a bug.)

2. **`verify.md` — the "forced ⇒ falsify side-by-side" gate must audit the
   *obligation*, not just run the two columns.** Today the gate (line 56) keeps
   "forced" if the alternative "demonstrably fails a public obligation." Add: *the
   blocking obligation must itself pass `SPEC_AUDIT` as `intent-derived` and must not
   be contradicted by any SUSPECT-triggering issue quote.* An obligation whose only
   support is a current-behavior doc/test that the issue disputes is `ambiguous`, and
   "the alternative fails an ambiguous obligation" makes the choice **under-determined,
   not forced** — never CONFIRM. (This is the precise hole: O2 *looked* public, so the
   otherwise-correct derivation laundered the inversion.)

3. **`intent-evidence.md` §3/§4 — read deprecation/removal language by its *positive
   replacement behavior*, not as "⇒ error".** Add a default-domain note: "*deprecate/
   remove implicit X*" means *X stops happening silently and the explicit form is
   required to OPT IN* — it does **not** by itself license raising on the implicit
   case; the post-removal behavior is the *non-promoted default* (here: treat the
   field as ordinary + auto-create the real link). Require citing the *replacement*
   behavior, not just the deprecation sentence, before encoding an error obligation.
   (Targets the transcript [line 43] inversion at its source.)

4. **`verify.md` Honesty gate — when the audit's whole no-change rests on ONE
   contested boundary, force an explicit UltimatePowers escalation, not a
   self-resolution.** fvk's own `ITERATION_GUIDANCE.md` Q1 *names* the exact pivot
   ("should a lone unmarked OTO keep raising ... or auto-create `…_ptr`?") and then
   answers it (a) itself from the misread doc. Add: if a single
   ambiguous/SUSPECT-touching boundary is the *sole* obstacle between V1 and a named
   alternative, the run is **unresolved pending clarification** — it may not be
   reported CONFIRM. That converts this from a confident wrong CONFIRM into a flagged
   open question, which is the honest outcome under hidden tests.

If none of (1)-(3) lands, the residual is genuinely low-headroom-by-knowledge: the
agent would have to *correctly* interpret a subtle deprecation semantics that it
read but misunderstood — a reasoning-quality limit, not a missing-information limit.
But because the issue text itself flatly states the disputed error **is the bug**,
the correct signal *was* present and out-ranked; (1)+(2) are the materially right
levers.
