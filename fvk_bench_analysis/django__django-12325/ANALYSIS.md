# Analysis — `django__django-12325` (FVK arm, batch1-XC-MINI-PRO-AHP)

**VERDICT: STATED** (root cause + exact correct fix explicitly named in the
artifacts; FVK reasoned itself to the wrong conclusion). **Reachable from public
data: YES.** **Counts toward headroom: YES.**

This is *not* a wrong-scope case (unlike the two prior batch1 instances). FVK
formalized the exact region the oracle patch fixes, quoted the oracle's exact
one-line change verbatim, and then explicitly rejected it based on a stale premise.

---

## 1. Root cause

**Bug:** In multi-table inheritance, when a child model has one or more
`OneToOneField`s to its parent, Django mis-identifies which field is the MTI parent
link, and spuriously errors on legitimate configurations.

**Location (oracle patch, `evidence/oracle_patch.diff`):**

1. `django/db/models/base.py`, `ModelBase.__new__`, the `parent_links` collection
   loop (~line 204):
   ```diff
   -                if isinstance(field, OneToOneField):
   +                if isinstance(field, OneToOneField) and field.remote_field.parent_link:
                        related = resolve_relation(new_class, field.remote_field.model)
                        parent_links[make_model_tuple(related)] = field
   ```
2. `django/db/models/options.py`, `Options._prepare` (~lines 251-255): delete the
   now-wrong guard (and the unused import):
   ```diff
                    field.primary_key = True
                    self.setup_pk(field)
   -                if not field.remote_field.parent_link:
   -                    raise ImproperlyConfigured('Add parent_link=True to %s.' % field,)
   ```

**Why it's a bug.** The original `isinstance(field, OneToOneField)` predicate is too
broad: *any* OTO to the parent is stored in `parent_links` (a dict keyed by parent),
so the **last-declared** OTO overwrites earlier ones — even overwriting the field
explicitly marked `parent_link=True`. `Options._prepare` then promotes that wrong
field to pk and, if it isn't a parent link, raises
`ImproperlyConfigured: Add parent_link=True to ...`. Hence (a) declaration order
decides the outcome, and (b) even a single *plain* OTO to the parent (no parent_link
intended) wrongly raises, instead of letting Django auto-create a `*_ptr` parent
link.

**Correct fix.** Only record fields actually flagged `parent_link=True` in
`parent_links`; everything else is left to auto-`*_ptr` creation. The `_prepare`
guard then becomes both unreachable for the wrong reason and incorrect, so it is
removed. Order no longer matters; lone plain OTOs no longer error.

**Bug TYPE:** wrong / under-specified condition (a **missing predicate** —
`and field.remote_field.parent_link` — in a dispatch), coupled with a **misplaced
precondition check** (the `ImproperlyConfigured` raise) that fires on valid input.

**FAIL_TO_PASS (`eval/fvk.report.json`):**
`test_clash_parent_link (...ComplexClashTests)` and
`test_onetoone_with_parent_model (...OtherModelTests)`. The gold patch makes both
pass (`test_output.txt`: `OK (skipped=2)`). Crucially, the test patch **deletes the
pre-fix `test_missing_parent_link`** and replaces it with assertions that a lone
plain OTO is now valid (`evidence/failing_tests.md`).

**Public-data reachability: YES, strongly.** The public `hints_text` literally states
the fix ("Not sure why we're not checking and `field.remote_field.parent_link`..."),
supplies the exact simpler reproducer that becomes `test_onetoone_with_parent_model`
and calls it "this bug," and challenges the very premise FVK preserved ("Having pk
OneToOne ... should imply it's parent link"). See `evidence/public_data_reachability.md`.

---

## 2. What the fvk arm did (V1 vs final + key artifacts)

**V1 = final = control (identical).** All three `solutions/*.patch` share md5
`0aa79605b945ac451d9f2fbdc50f02b5`. FVK **confirmed** V1; it changed nothing
("V1 stands unchanged", `fvk/ITERATION_GUIDANCE.md:9`).

V1's patch touches only `base.py`: instead of the oracle's predicate, it keeps all
OTOs flowing into `parent_links` but adds a guard so a plain OTO won't *overwrite* an
already-recorded `parent_link=True` field; otherwise it preserves last-wins. It does
**not** touch `options.py`.

```python
existing = parent_links.get(related_key)
if (existing is not None and existing.remote_field.parent_link
        and not field.remote_field.parent_link):
    continue
parent_links[related_key] = field
```

**Key artifact contents** (all present; two `.k` files):
- `SPEC.md` — target = the correct loop (`base.py:194-219`); intent ledger quotes the
  issue and the `field.remote_field.parent_link` hint; postcondition = biconditional
  **I2** (parent-link priority, order-independent) + **I3** (legacy last-wins
  fallback) + **D** (domain preserved). Explicitly traces the `options.py` /
  `ImproperlyConfigured` consumer (section 5).
- `FINDINGS.md` — F-2 = the order-dependence bug V1 fixes; **F-4 = the smoking gun**
  (rejects the oracle one-liner); F-9 = "clean spec, complete" false reassurance;
  "no finding requires changing V1."
- `PROOF_OBLIGATIONS.md` — PO-1..PO-14 discharging I1/I2/I3/D; the list-induction VCs
  (PO-7/8/11/14) marked `[ESCALATION BOUNDARY]` (kit capability gaps, not code bugs).
- `PROOF.md`, `ITERATION_GUIDANCE.md` (G-1 keep the guard; G-2 defer a "multiple
  parent links" *system check* to a separate change), `reports/fvk_notes.md`
  (Decision 2 = keep the fallback).
- `mti_parent_links.k` / `-spec.k` — model the loop as `skip`/`updateSel`; the
  `(SELECT-PL)` claim's `ensures` encodes I2 **and I3** formally.

---

## 3. Artifact audit — VERDICT: **STATED**

The faulty thing and the correct-fix direction are explicitly named.

**Exact excerpt (the single most important one), `fvk/FINDINGS.md:78-84` (F-4):**
> "This finding is why the fix must **not** be the tempting one-liner 'only record
> `parent_link=True` fields' (`if isinstance(field, OneToOneField) and
> field.remote_field.parent_link`). That variant would drop the lone non-parent OTO
> from `parent_links`, silently auto-create `place_ptr`, and **break this test**."

Reinforced at `fvk/ITERATION_GUIDANCE.md:23-31` (G-1) and
`reports/fvk_notes.md:58-71` (Decision 2). The oracle's `base.py` change is quoted
character-for-character; FVK chose against it.

**Why STATED (pointed-at-the-spot, to the cause):** pointed at F-4/G-1, a
knowledgeable reader sees the exact correct fix written out, applied to the exact
buggy construct, in the exact buggy file. The information needed to flip this failure
is fully present — the agent simply concluded the opposite.

**The error in FVK's reasoning (why V1 still fails):** FVK treated the *pre-fix*
`test_missing_parent_link` (present at the base commit, asserting a lone OTO must
raise) as an authoritative public contract (G-1 UltimatePowers Q&A: "-> Yes (it has a
dedicated test). So the fallback-to-last behaviour (I3) is required."). But the gold
test patch **deletes that test** and asserts the opposite
(`test_onetoone_with_parent_model`: lone OTO is valid). FVK's proved invariant **I3**
(`fvk/SPEC.md:84-87`; formalized at `mti_parent_links-spec.k:88-89`) is the precise
formal encoding of the bug V1 retains. And FVK never proposed the oracle's *second*
hunk — deleting the `options.py` `ImproperlyConfigured` raise — even though it read
that raise (`fvk/SPEC.md:103-104`) and classified it as a contract to satisfy rather
than a defect to remove.

This is the primer section v(7) "clean/total => false reassurance" pattern (F-9:
"clean, total biconditional ... complete for the issue"), but here uniquely on the
**right** region with the **right** fix explicitly in hand. Not BURIED (it is
surfaced as plain prose, not just latent in a PO/`requires`); decisively not MISSING.

`[ESCALATION BOUNDARY]` markers (PO-7/8/11/14) are kit-capability gaps and are not
treated as findings — correct per primer section v(2)/vi.

See `evidence/artifact_excerpts.md` for the full quote set with line numbers.

---

## 4. How FVK could surface it (prose, general, no-exec)

The information was already produced; the gap is in *trusting in-repo tests as
ground-truth intent* and in *checking the fix against the full issue intent*:

1. **Do not treat an existing test as the authoritative contract when the issue
   argues that behavior is wrong.** FVK elevated `test_missing_parent_link` to a
   binding contract (G-1). A guard in the methodology: when the intent ledger quotes
   issue text that *contradicts* a current test's premise ("Having pk OneToOne ...
   should imply it's parent link"; the simpler reproducer called "this bug"), flag a
   **spec/intent vs. existing-test divergence** rather than siding with the test. The
   pre-fix test may itself be what the change deletes.

2. **Spec the alternative fix, don't just dismiss it.** F-4 names the oracle one-liner
   and rejects it on a single feared regression. FVK should have written the
   competing postcondition for "record only parent_link fields" and checked it against
   the issue's *full* intent (including the lone-OTO reproducer the issue calls a
   bug) — at which point the oracle contract satisfies the issue and V1's I3 does not.

3. **Audit the whole consumer chain for fixes, not just for assumptions.** FVK
   correctly traced `parent_links -> Options._prepare -> ImproperlyConfigured`
   (SPEC section 5) but used it only to argue "no spurious error." The same trace,
   asked "could this raise itself be wrong for a valid input?", surfaces the oracle's
   second hunk (delete the `options.py` raise).

4. **Resist "clean/total => complete" when the domain was drawn to match V1.** I2/I3
   are "clean" only because I3 *defines* the lone-OTO error as intended. Cross-check
   the SPEC domain against every reproducer in the issue; the lone-OTO reproducer was
   in the public hints and should have broken the "total/complete" claim.
