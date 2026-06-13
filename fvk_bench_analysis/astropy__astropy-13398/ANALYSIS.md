# astropy__astropy-13398 — FVK artifact failure analysis

**Batch:** `batch1-XC-MINI-PRO-AHP`  ·  **Arm result:** FAILED (resolved=False; baseline/control/fvk verdicts identical — 0/4 FAIL_TO_PASS, +5 PASS_TO_PASS regressions).
**VERDICT: MISSING — but fully reachable from public data.** Counts toward headroom: **NO** (no latent signal in the artifacts). FVK gap: **YES, severe** (the defect was spelled out in the public issue and the agent even read the exact fix pattern, yet none of it reached the FVK artifacts).

---

## 1. Root cause

**What the issue asks for (feature, PR #13398):** a *direct, topocentric* `ITRS ↔ AltAz/HADec` transform that stays in the rotating ITRF (pure rotation, no stellar aberration), so near-Earth objects come out correctly; plus making `ITRS` able to *carry* an observer location.

**Where the gold patch fixes it** (`evidence/oracle_patch.diff`, 4 locations):
1. **`builtin_frames/itrs.py`** — adds `location = EarthLocationAttribute(default=EARTH_CENTER)` to class `ITRS`. *Without this, `ITRS(..., location=...)` raises `TypeError: Coordinate frame ITRS got unexpected keywords: ['location']`.*
2. **`builtin_frames/intermediate_rotation_transforms.py`** — `tete_to_itrs`/`cirs_to_itrs` use `location=itrs_frame.location` (was hardcoded `EARTH_CENTER`); `itrs_to_tete`/`itrs_to_cirs` rebuild TETE/CIRS with `location=itrs_coo.location` (was dropped). Lets the observer location survive ITRS<->CIRS round-trips.
3. **`builtin_frames/itrs_observed_transforms.py`** (new) — the direct transforms, **with optical refraction** ported from ERFA (`add_refraction`<-`erfa.atioq`, `remove_refraction`<-`erfa.atoiq`), and a guard that only re-references through CIRS when `location`/`obstime` actually differ.
4. **`__init__.py`** — registers the module.

**Bug type:** missing-feature / incorrect-algorithm for near-Earth objects (geocentric-SSB aberration applied where topocentric is required), compounded by a **missing frame attribute** (`ITRS.location`), a **missing transform edge**, **lost observer state** in the CIRS/TETE bridges, and a **missing refraction model**.

**Public-data reachability: HIGH (architecture + both incompletenesses are explicit in the issue).** The `problem_statement` ships a near-complete reference implementation and the maintainer thread; it literally contains (a) the `TypeError ... unexpected keywords: ['location']` traceback proving `ITRS` lacks `location` (`evidence/transcript_excerpt.txt` row 8, issue lines 167-175), and (b) the sentence *"I have yet to add refraction, but I can do so if it is deemed important"* (row 8, issue line 31). The hidden FAIL_TO_PASS tests only pin the **numbers** (Alt=90 deg to 1 uas; ITRS-route vs normal-route to 0.1 mas; distance to 10 cm) and force refraction + location-through-CIRS to actually be implemented — they don't introduce a cause invisible in public text.

**FAIL_TO_PASS (all 4 failed under fvk):** `test_itrs_straight_overhead` (needs `ITRS(location=)` + no-aberration zenith->Alt 90 deg), `test_cirs_itrs_topo` (location must survive CIRS<->ITRS), `test_itrs_topo_to_altaz_with_refraction`, `test_itrs_topo_to_hadec_with_refraction` (direct path must match the normal route *with refraction*). See `evidence/failing_test_snippet.txt`.

---

## 2. What the fvk arm did (V1 vs final)

**V1 = baseline patch** created only `__init__.py` + `itrs_observed_transforms.py` with three functions (`itrs_to_observed_mat`, `itrs_to_observed`, `observed_to_itrs`). Critically, **V1 never touches `itrs.py`** (no `ITRS.location`), **never touches `intermediate_rotation_transforms.py`**, and **has no refraction** (confirmed: `grep` of the baseline patch finds no `EarthLocationAttribute`, no `itrs.py`, no `refraction`/`refco`/`atioq`). V1 is therefore *structurally* incomplete vs. the gold requirement on three public-derivable axes.

**fvk final = V1 + one kwarg.** `diff` of the two patches (`evidence/baseline_vs_fvk_patch.txt`): the **only** substantive change is `finite_difference_frameattr_name=None` added to the four `@transform` decorators (+ comment). The transform **bodies are byte-identical**. fvk **confirmed** V1; it did not repair it.

**FVK artifacts** (markdown-only — no `.k`, as expected for loop-free code; `SPEC.md:8-12`):
- **SPEC.md** formalizes the three functions as clean pre/post contracts: `M*(P-L)` / `M^T*Q+L`, with "no aberration, no refraction" stated as *intent* (`SPEC.md:23`). Declares the contract "clean and total on its domain" (`SPEC.md:99-107`).
- **FINDINGS.md** — 6 findings, all **positive or low-severity fail-safe UX**: F5 "geometry and round-trip are correct (positive)... No off-by-sign, no axis swap" (`FINDINGS.md:93-101`); headline "no input produces a silent wrong answer" (`FINDINGS.md:3-7`). Only F4 (`obstime=None` + velocity -> `None+dt` `TypeError`) is applied — the kwarg.
- **PROOF_OBLIGATIONS.md / PROOF.md** — PO1-PO9: orthogonality, exact round-trip, geometric anchors, obstime-independence; anchors marked `[ESCALATION BOUNDARY]` (real-trig, a *capability* gap) and "discharged by hand."
- **fvk_notes.md** Decision 1: "keep the matrix-build and the two transform bodies unchanged... Changing them would only risk diverging from the reference implementation that the hidden tests pin." Final: "core transform logic **confirmed correct on its domain** and is left unchanged."

The audit scoped itself **entirely to the three functions present in V1** and asked only orthogonality/round-trip/velocity questions (transcript A83/A86/A90/A93). It never asked "is V1 *complete* vs. the issue?"

---

## 3. Artifact audit — VERDICT: MISSING (reachable)

The true root cause has three public, concrete components. **None appears anywhere in the FVK artifacts or notes.** Documented absence (searched `fvk/SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, `ITERATION_GUIDANCE.md`, `reports/fvk_notes.md`):

| Root-cause component | grep over all fvk artifacts + notes | In artifacts? |
|---|---|---|
| Missing `ITRS.location` (`EarthLocationAttribute`) | `EarthLocationAttribute` -> **0 hits**; no text saying ITRS needs/lacks a location attribute (the `location` hits are all `AltAz/HADec.location` in finding inputs) | **No** |
| Missing refraction (`atioq`/`atoiq`/`refco`/`pressure`) | only `SPEC.md:23` "No aberration, **no refraction**" — asserted as *intended scope*, not as a gap | **No (mis-scoped)** |
| Lost location in `intermediate_rotation_transforms.py` (CIRS/TETE, `EARTH_CENTER`) | `intermediate_rotation`, `EARTH_CENTER`, `cirs_to_itrs`, `itrs_to_cirs` -> **0 hits** | **No** |

"Pointed-at-the-spot" test: there is **no excerpt** a knowledgeable reader could be pointed to that encodes any of these. The closest lines point the *wrong way*:
- `SPEC.md:99-107` — "The contract is **clean and total on its domain**... the spec is clean => this is weak positive evidence the code has no hidden corner-case bug." The "if a clean spec is hard, that's a bug signal" heuristic was **inverted into false reassurance** by formalizing only the slice V1 implemented and excluding refraction/location by fiat.
- `FINDINGS.md:93-101` (F5) and `PROOF.md` 3.1/PO5 "prove" the geometry by mapping the `(lon,lat)`-derived ENU basis back to the observed axes — **circular**: the "ground truth" is built from the same matrix under test, so it cannot detect a missing dimension of the problem, let alone a missing attribute/feature.

**The signal existed in the agent's own inputs but never crossed into the artifacts** (`evidence/transcript_excerpt.txt`):
- The public issue (transcript row 8) shows the `TypeError ... unexpected keywords: ['location']` and "I have yet to add refraction."
- The agent **read** `altaz.py`/`hadec.py` (rows 22/24) seeing `location = EarthLocationAttribute(default=None)` + `pressure` refraction attrs, and **read** `cirs_observed_transforms.py`/`icrs_observed_transforms.py` (rows 28/30) which use `erfa.atioq`/`atoiq` **and** rebuild CIRS with `location=observed_coo.location` — the exact fix pattern.
- Yet in the FVK recap (A94) refraction is listed under **"rejected alternatives"**, and the only near-miss (baseline A49/A54: the new ITRS->AltAz edge collides with `test_gcrs_altaz_bothroutes`) was waved off as "the gold test patch will update this." That collision is real: `test_gcrs_altaz_bothroutes` shows up as **5 PASS_TO_PASS regressions** in `eval/fvk.report.json`.

**Why MISSING and not BURIED:** BURIED requires the signal to be present in formal form (a forced `requires`, an undischarged VC on the buggy path, a spec/intent divergence). Here the artifacts contain none — the missing attribute/feature/state were *defined out of scope* before any obligation was written, so no precondition, no PO, and no `[ESCALATION BOUNDARY]` sits on them. The escalation boundaries that do exist are on real-trig orthogonality (a genuine kit capability gap), not on the defect.

**Reachable?** Yes — emphatically. The cause is in the public issue verbatim and in source the agent actually opened. This is **MISSING-but-reachable**: it does **not** count toward latent headroom (the info isn't in the artifacts to be "surfaced/de-noised"), but it is a real FVK process failure, not an information-theoretic limit.

---

## 4. How FVK could surface it (prose, general, no-exec)

1. **Spec the issue's intent ledger first, then check the patch *covers* it — completeness, not just local soundness.** FVK's stated day-one value is "if a clean spec is hard, the code has a bug." The dual must be enforced: build the SPEC's intent ledger from the *whole* problem statement, then require every intent clause to map to applied code. Here the ledger would carry two unfixed clauses straight from public text — *"ITRS must accept a `location`"* (the `TypeError` traceback) and *"refraction may be required"* — and V1 satisfies neither. A spec that *excludes* a documented intent clause ("no refraction") should be flagged as a **spec/intent divergence**, not recorded as settled scope.
2. **Treat "I have yet to add X" / error tracebacks in the issue as obligations, not prose.** Any literal exception or "not yet implemented" admission in the problem statement should become a precondition/obligation the audited code must discharge.
3. **Don't let the spec's domain be drawn around exactly the code that exists.** Declaring the contract "total on its domain" is vacuous when the domain was chosen to match V1. Anchor the domain to the *tests/intent* (topocentric ITRS *with a location*, refraction on), which immediately exposes that V1 can't even be instantiated on it.
4. **Geometry "proofs" must compare against an independent reference, never a basis built from the matrix under test.** PO5/PO6 here are self-consistent and so blind to whole missing dimensions; a single concrete reference value (or the colliding `bothroutes` test the agent already saw) would have broken the circularity.

---

*Evidence:* `evidence/oracle_patch.diff` - `evidence/baseline_vs_fvk_patch.txt` - `evidence/failing_test_snippet.txt` - `evidence/fvk_artifact_excerpts.md` - `evidence/transcript_excerpt.txt`.
