# FVK primer — a decoder ring for the artifact audit

You will read **one** failing instance's FVK artifacts and judge **one** thing:
**is the instance's known root cause present (possibly disguised) in those
artifacts, or missing?** This primer tells you what each artifact *should*
contain, the notation you'll hit, and — most importantly — **how a real code bug
tends to show up inside FVK's formal machinery**. It orients; it does not replace
the sources. Quote-anchored claims cite paths under
`third_party/formal-verification-kit/` (abbreviated `tp/fvk/` below). Consult the
primary source when depth matters.

> **Read this caveat first.** Almost every emitted artifact is labelled
> *"constructed, NOT machine-checked"* — the kit builds proofs and emits
> `kompile`/`kprove` commands but **never runs the toolchain**
> (`tp/fvk/commands/verify.md:33-36`, "does NOT run `kompile`/`kprove`"). It also
> models only a hand-written **"mini-X" fragment** of the language, not the real
> language (`tp/fvk/README.md:158-162`). So a proof "succeeding" is an *argument*,
> not a verdict. Do **not** mistake these KIT limitations for ANALYSIS findings.

---

## (i) What FVK is for + honest status

FVK writes a formal **spec** for code (a pre/postcondition contract per function,
an invariant per loop) and **constructs** a correctness proof, surfacing bugs as a
plain-language **Findings report** (`tp/fvk/README.md:24-36`). Its self-declared
day-one value is *"surfacing hidden subtle bugs"* — *"if a clean specification is
hard or impossible to write, that is itself strong evidence the code has a bug"*
(`README.md:30-32`). This signal is your friend: it is exactly where root causes
leak out.

Honest limits, in the kit's own words (`README.md:147-166`):
- **Constructed, not machine-checked** — no prover is run.
- **Fragment ("mini-X") semantics** — *"a minimal K semantics covering only the
  constructs your code actually uses"* (`commands/formalize.md:108-124`). The
  semantics is itself author-written and may be wrong or too coarse.
- **Partial correctness by default** — *"correctness if the function returns"*;
  termination is only a recommendation.

The kit is rough / "vibe-coded": primers repeatedly call themselves a *"fast
path"* that is *"deliberately incomplete"* (`knowledge/matching-logic.md:129-131`).
Treat artifact content as an LLM's reasoning, formatted as math — credible, but
not authoritative.

## (ii) The artifact set — what each file should contain

The kit's idealized output (`commands/formalize.md:249-258`, `verify.md:214-235`)
is `FINDINGS.md`, `SPEC.md`, `PROOF.md`, and `<mod>.k` + `<mod>-spec.k`. **Real
emitted sets add two files** the kit never specifies (see §viii):

- **`SPEC.md`** — human-readable contract: an **intent ledger** (quoted evidence
  from `benchmark/PROBLEM.md` / the issue, mapped to obligations,
  `knowledge/intent-evidence.md:24-37`), the precondition / postcondition of each
  function, side conditions, and scope. **This is your highest-value file**: the
  root cause, if captured, is usually a sentence here.
- **`FINDINGS.md`** — plain-language `input → observed vs expected` bug list
  (`formalize.md:208-221`). In real runs each finding carries a verdict marker
  (✅ confirms the fix · ✏️ drove a refinement · ⚠️ open / spec-difficulty).
- **`PROOF_OBLIGATIONS.md`** — *(real runs only)* a numbered table of facts the
  proof needs (PO-1, PO-2, …), each with "how discharged" and a status
  (✅ / ◑ residual at escalation boundary). A root cause often hides as one PO.
- **`PROOF.md`** — the constructed proof write-up: claims restated, symbolic
  execution sketch, VC discharge, residual risk, test-redundancy.
- **`<mod>.k`** — the mini-X **semantics** (syntax + config cells + rewrite rules)
  modelling the fragment the fix touches.
- **`<mod>-spec.k`** — the **claims** (`claim … [all-path]`) plus
  `[simplification]` lemmas and spec-only abstraction functions.
- **`ITERATION_GUIDANCE.md`** — *(real runs only)* the decision this pass,
  open items, "UltimatePowers questions", rejected alternatives.

## (iii) K / matching-logic notation you'll actually encounter

A K **configuration** is a tuple of named **cells**; `<k>` holds the running
computation (`knowledge/k-framework.md:93-101`):
```
<k> $PGM </k>  <store> .Map </store>  <objs> .Map </objs>  <next> 0 </next>
```
You'll meet (minimal set):
- **`=>`** — rewrite / the reachability arrow. In a `claim`, `<k> LHS => .K ...`
  means "this code runs to completion"; `x |-> (OLD => NEW)` means variable `x`
  goes from `OLD` to `NEW` (`k-framework.md:180-200`).
- **`requires`** = **precondition**; **`ensures`** = **postcondition**
  (`k-framework.md:198-202`). *A `requires` is an assumption the proof is allowed
  to make — read every one skeptically (see §v).*
- **`claim … [all-path]`** — a reachability rule `φ_pre ⇒ φ_post`
  (`knowledge/reachability-and-circularities.md:23-50`). `[all-path]` = every
  execution; `[one-path]` = some execution.
- **`|->`** map binding, **`M[K <- V]`** map update, **`.Map`/`.List`/`.Set`**
  empty (`k-framework.md:112-116`).
- **`#And #Or #Not #Exists #Equals`** = matching-logic `∧ ∨ ¬ ∃ =`; **`#Top`** =
  "proved / discharged" — the success token (`matching-logic.md:120-127`).
- Uppercase = logical variables (`N`,`S`), lowercase = program variables
  (`n`,`s`) (`formalize.md:135-136`). `?`-prefixed = existentials ("some value").
- **`[simplification]`** rules = author-supplied lemmas feeding the arithmetic
  oracle; **`[function]`** = a **spec-only abstraction** (e.g. `reach`, `isSorted`,
  `bag`) — vocabulary invented for the spec, *not* a language construct
  (`k-framework.md:307-323`).

Concrete claim (the worked arithmetic example,
`tp/fvk/examples/02-sum-up/mini-python-spec.k:70-84`): `<k> … result = sum_to_n(N) => .K …</k>`
with `<store> result |-> (_ => N *Int (N +Int 1) /Int 2) </store> requires N >=Int 0`.

## (iv) The reasoning rules that matter — invariants & circularity

For loops/recursion, FVK doesn't invent a classical invariant; it states the
loop/function's **own claim as a coinductive hypothesis** — a **circularity** —
usable after ≥1 real step (`reachability-and-circularities.md:78-123`). What this
lets it *detect*:
- A **loop invariant / closed form it cannot write cleanly** ⇒ flagged as
  spec-difficulty ⇒ usually a real missing case (`verify.md:132-137`).
- A **soundness side condition forced onto the loop** (e.g. `I <=Int N +Int 1`):
  *"a side condition you are forced to add … is usually a precondition the code
  silently assumed and never checked"* (`verify.md:250-256`;
  `reachability-and-circularities.md:230-235`).

## (v) HOW ROOT CAUSES MANIFEST — the "tells" (the core of your job)

A code bug rarely appears as the word "BUG". It leaves **fingerprints in the
formal scaffolding**. When the known root cause matches one of these, score it
**PRESENT even if disguised**:

1. **A precondition the proof is *forced* to assume = latent missing-precondition.**
   A `requires N >=Int 0` / `location is not None` / `acyclic(...)` that the code
   doesn't itself enforce is the spec admitting the code only works on a subset of
   inputs. The canonical worked tell: the `n >= 0` finding
   (`examples/02-sum-up/FINDINGS.md:10-32`). **If the root cause is "code mishandles
   input X" and the spec quietly excludes X via `requires`, the cause is PRESENT
   (hidden in the precondition).**

2. **An undischargeable / `[ESCALATION BOUNDARY]` obligation on a branch = latent
   unhandled case** — *but only sometimes.* The kit insists capability gaps
   (inductive-set / multiset VCs) are *"NOT a code bug"* (`verify.md:138-143`).
   So: an escalation boundary on *sortedness/heap* machinery is usually a KIT
   limitation; an undischarged VC sitting **exactly on the buggy branch / value**
   is a code tell. Read *which* obligation is open.

3. **A `claim`/postcondition that *diverges* from documented intent = latent wrong
   behavior.** Compare `SPEC.md`'s quoted intent against the postcondition. If the
   intent says "report the provided value" but the contract/finding shows a
   normalized value, the divergence *is* the root cause. **Caveat — verify the
   divergence sits on the *graded* defect:** `django-13212` F3 has exactly this shape
   (intent = provided value vs V1 = punycode/ACE-normalized) and fvk even fixed it —
   but F3 is a `URLValidator` finding *orthogonal* to that instance's graded failure
   (a `DecimalField.validate` NaN short-circuit in `forms/fields.py`), whose cause is
   MISSING (scope-fenced out → tell #7). A correctly-shaped divergence on the wrong
   target does not count.

4. **A Finding stated as `input → observed vs expected` where observed≠expected.**
   This is the most direct tell — but in this audit most findings are framed as
   **confirming an already-applied fix** (✅), so the root cause appears as *"what
   V1 corrects"* / *"the bug this prevents"*, narrated in past tense. The mutation
   mechanism described in `SPEC.md`/`PROOF.md` ("if X were shared, reset Y corrupts
   Z") *can be* the root cause, just told as the thing being fixed. **But verify the
   mechanism is the RIGHT one** — apply pointed-at-the-spot to the *cause*, not the
   symptom string. **Decoy counter-example (`django-10554`):** the artifacts quoted
   the issue's error string but modeled an *unrelated* mechanism (`Query.clone()`
   deep-copy / aliasing) while the true cause — a missing case in `get_order_by` —
   was never mentioned. A symptom-string match wrapped around the wrong mechanism is
   **MISSING with a decoy**, not PRESENT.

5. **Spec-difficulty / awkward case-split / "could not reproduce" admissions.** A
   ⚠️ finding, a postcondition needing ugly case splits, or a "hard to write a
   clean spec here" note (`formalize.md:222-226`) frequently sits right on top of
   the root cause. Treat honest hedging as a pointer, not noise.

6. **A PO whose "how discharged" is `✅(code)` by inspection of the exact buggy
   construct.** The obligation table often *names* the fragile fact (a guard, a
   shared object, an attribute write-set). If the root cause is that fact, it's
   PRESENT even though the PO marks it "discharged".

7. **Scope-induced false-negative — "clean / total on its domain" is NOT a PRESENT
   tell, and often masks a MISSING.** When V1 is *incomplete* versus the issue, FVK
   tends to draw the spec domain around exactly the code that already exists, then
   declares the contract *"clean and total on its domain"* — inverting the "hard
   spec ⇒ bug" heuristic into false reassurance (real tell:
   `astropy-13398/fvk/SPEC.md:99-107`). The root cause was *defined out of scope*
   before any obligation was written, so no `requires`, no PO, and no escalation
   boundary sits on it → verdict **MISSING-but-reachable**, not BURIED. Guard:
   cross-check the SPEC's domain / intent ledger against the issue's *full* intent
   (error tracebacks, "I have yet to add X" admissions); a documented intent clause
   the spec *excludes* is itself a divergence, and a domain chosen to match V1 makes
   "total" vacuous.

8. **STATED-but-reasoned-against — the artifact *names the correct fix, then argues
   against it.* (PRESENT → counts toward headroom.)** The strongest "present" case:
   a finding quotes the oracle's exact fix and then *rejects* it — typically because
   FVK treated an **existing, pre-fix in-repo test as binding ground-truth intent**
   and proved an invariant that *preserves the bug*. Real tell:
   `django-12325/fvk/FINDINGS.md:78-84` (F-4) quotes
   `if isinstance(field, OneToOneField) and field.remote_field.parent_link` verbatim,
   calls it "the tempting one-liner" that "would break this test" — but the gold patch
   *deletes* that test and asserts the opposite. When the correct fix is dismissed on
   the authority of a test the issue implies is wrong, score **STATED** (FVK localized
   perfectly and held the answer; the failure is acting on it). **Broader form:** the
   rejection can rest on *any* constructed argument, not just a binding test — incl. a
   logically-flawed "forcing" proof obligation that fabricates a requirement for the
   buggy behavior and even predicts the (wrong) hidden-test expectation. Real tell:
   `pytest-10356/fvk/FINDINGS.md` F2 + `PROOF_OBLIGATIONS.md` PO3 declare the walk
   "must be `reversed(__mro__)`" and predict base-first `[b,a,c]` — the exact
   inversion of the required `[c,a,b]`; the single token `reversed` is the whole bug.
   This exposes a real risk of *constructed, not machine-checked* proofs: they can
   manufacture confident-but-false obligations. Distinct from #7 (false reassurance →
   MISSING) and from wrong-scope MISSING.

9. **FVK *certifies the buggy behavior as the spec* (formalized the implementation,
   not the intent) → MISSING via false-positive certification.** Worse than #7's
   silent exclusion: here the spec's *postcondition is the wrong output*, and a
   finding asserts it **POSITIVE / correct**. The kit explicitly forbids this ("don't
   formalize whatever the code happens to do"), yet under the "confirm V1" framing it
   recurs. Real tell: `django-16263/fvk/FINDINGS.md:100-106` (F6 "POSITIVE … →
   `SELECT COUNT(*) FROM book`") + `SPEC.md:9-13` — the single-SELECT shape V1's bug
   produces is enshrined as the contract, while the SQL-shape axis the tests actually
   measure is abstracted away by the mini-ORM and fenced `[ESCALATION BOUNDARY]`.
   When the spec's postcondition equals the buggy output, the root cause is
   **MISSING (inverted)**, not BURIED — the artifacts point the wrong way.

**Disguise patterns to expect:** root cause split across several POs; stated only
as a side condition; described as the rationale for the fix rather than as a defect;
or buried in the `<mod>.k` semantics (e.g. an `in-place` mutation rule that models
the aliasing bug). Skim the `.k` files for the *mechanism*, not just the markdown.

## (vi) Blind spots — where "MISSING" is fair

FVK structurally cannot surface some bug classes, so absence there is **not**
evidence the analyst missed it:
- **Anything outside the mini-X fragment.** The semantics covers only chosen
  constructs (`formalize.md:108-124`); a bug in unmodelled code/control-flow simply
  isn't represented.
- **Termination / performance / complexity** — partial correctness by default
  (`README.md:163-166`); infinite loops, O(n²), resource bugs won't show.
- **Concurrency, exceptions, I/O, the heap, binders** — explicit escalation cases,
  routinely *not modelled* (`commands/formalize.md:175-180` models the *reduced
  in-domain body* and drops `raise`).
- **Relational properties over data structures** (sortedness, permutation) — hit
  the escalation boundary and are stated, not proved (`k-framework.md:318-323`).
- **Integration / cross-module wiring** — the proof covers the unit, not the
  wiring (`verify.md:200-203`).
- **Bugs the author simply didn't model.** Coverage is whatever the FVK agent
  *chose* to formalize; a real cause it ignored leaves no trace.

When the root cause falls squarely in a blind spot, **MISSING is a fair verdict** —
say so and cite the blind spot.

## (vii) Primary-source map

| Topic | Read |
|---|---|
| Purpose, honest status, MVP limits | `tp/fvk/README.md` (§"Honest status" L147-166) |
| `/formalize` workflow, intent-spec mode, Findings shape | `tp/fvk/commands/formalize.md` |
| `/verify` workflow, proof construction, escalation, honesty gate | `tp/fvk/commands/verify.md` |
| K notation: cells, `=>`, `requires`/`ensures`, claims, `/Int` | `tp/fvk/knowledge/k-framework.md` |
| Matching logic: patterns-as-sets, `#And/#Or/#Equals`, `#Top` | `tp/fvk/knowledge/matching-logic.md` |
| Reachability, the Circularity rule, side-condition-as-bug-signal | `tp/fvk/knowledge/reachability-and-circularities.md` |
| Intent ledger & spec provenance | `tp/fvk/knowledge/intent-evidence.md` |
| Worked arithmetic example (clean tells) | `tp/fvk/examples/02-sum-up/` (`.k`, `SPEC.md`, `FINDINGS.md`, `PROOF.md`) |
| Escalation done right (sortedness/permutation) | `tp/fvk/examples/12-insertion-sort/`, `06-sum-recursive/` |

## (viii) Gap: idealized examples vs. the real emitted artifacts

The kit's example is a tiny arithmetic function; the real instances are messy
gold-patch audits. Differences that affect your reading:
- **Two extra files** (`PROOF_OBLIGATIONS.md`, `ITERATION_GUIDANCE.md`) appear in
  every real run but are **not** in the kit's output contract — the PO table is
  where causes most often hide.
- **`.k` files are sometimes absent.** When the fix has no loop/recursion, the
  agent emits **markdown only** (e.g. `astropy-13398/fvk/` has zero `.k` files,
  `SPEC.md:9-12`). No `.k` ≠ incomplete.
- **Framing flips.** The kit hunts bugs in fresh code; real artifacts mostly
  **confirm an already-applied "V1" fix**, so the root cause is narrated as "what
  the fix prevents" (past tense, ✅), not as an open defect.
- **Escalation boundaries are pervasive** (≈18/19 batch1 instances) and lean on
  spec-only abstractions (`reach`, `acyclic`, `preservedOn`) far more than the
  arithmetic example. Per kit policy these are *capability* gaps, **not** code bugs
  — don't count them as the root cause unless the open VC sits on the buggy path.
- **Everything is "constructed, not machine-checked."** No `#Top` was actually
  produced. Weigh artifact claims as reasoning, never as verification.
