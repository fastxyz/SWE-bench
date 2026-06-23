# django__django-14539

## Summary

**Severity:** Medium — baseline still corrupts `urlize()` output when the trailing
punctuation is itself written as an HTML entity (e.g. `google.com/&#33;`), a
user-visible defect confined to URL/entity punctuation patterns.

Baseline and FVK both passed the official SWE-bench evaluation for issue #14539,
with **different** patches. Baseline correctly fixed the reported case — literal
punctuation after an escaped sequence such as `&lt!` — but left an unmet
obligation in the *same* source-span invariant: when the trailing punctuation
character is encoded as an entity, baseline trims only the final `;` and breaks
the entity. FVK located that residual case by **formalizing the issue as a
source-span trimming contract and auditing every trailing-suffix shape against
it**, not by running a new test (the public suite never exercises it).

| Arm | `test_urlize` / `test_urlize_unchanged_inputs` (public) | Entity-encoded trailing punctuation resolved |
|---|---|---|
| baseline | [PASS](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/eval/baseline.report.json) | no |
| gold (human oracle) | — | no |
| **fvk** | [PASS](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/eval/fvk.report.json) | **yes** |

## 1. The issue and the real defect

Issue #14539 — *`urlize()` duplicates characters from an escaped URL when trailing
punctuation follows an HTML entity*. The canonical repro
([`prompts/fvk.md`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/prompts/fvk.md#L7))
is `urlize('Search for google.com/?q=1&lt! and see.')`: the expected link text is
`google.com/?q=1&lt</a>!`, but the original code emitted `google.com/?q=1&lt</a>lt!`,
**duplicating** the `lt` (see finding
[F-001](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/FINDINGS.md#L6)).

`django.utils.html.urlize()` strips trailing punctuation off a candidate URL in
its nested `trim_punctuation()` helper. To avoid treating the `;` inside an HTML
entity as punctuation, the check is run on `html.unescape(middle)`. The original
code then mapped that decision back to the source string with an **absolute
index** measured in unescaped characters:

```python
trail = middle[len(stripped):] + trail
middle = middle[:len(stripped) - len(middle_unescaped)]
```

When `middle` contains an entity-like sequence such as `&lt`, the unescaped
string is shorter than the source, so `len(stripped)` points to the wrong source
offset — the user-facing link text comes out wrong.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/solutions/solution_baseline.patch)
replaced the absolute-index slice with a **count-based** slice: count how many
unescaped trailing punctuation characters must move, then move that many *source*
characters.

```python
punctuation_count = len(middle_unescaped) - len(stripped)
trail = middle[-punctuation_count:] + trail
middle = middle[:-punctuation_count]
```

Baseline was not careless. Its notes show it deliberately rejected the simpler
option of trimming directly off the escaped string, precisely because that would
corrupt valid entities:

> *"I considered trimming punctuation directly from the original escaped string,
> but that would treat the semicolon in valid entities as trailing punctuation
> and could corrupt link text such as `&amp;`."*
> — [`reports/baseline_notes.md`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/reports/baseline_notes.md#L40)

That reasoning fixes the reported `&lt!` case. But it silently assumes **one
visible punctuation character occupies one source character** — true for a
literal `!`, false when the punctuation is itself an entity. For
`google.com/&#33;` (`&#33;` decodes to `!`), `punctuation_count == 1`, so baseline
moves only the final `;`, leaving `google.com/&#33` in `middle` and `;` in
`trail`. The entity is broken. This is the exact obligation baseline left unmet
(finding
[F-002](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/FINDINGS.md#L21)).

## 3. How FVK formally captured the gap

FVK started from a spec, not the symptom. The intent ledger lifts the issue and
the in-code comment into two obligations, **I-001** (the reported behavior) and
**I-004** (the entity-preservation rule the comment already states):

> **I-004** | code comment | *`Unescape entities to avoid breaking them by
> removing ';'.`* | *Entity-aware trimming must not corrupt valid entity source
> spans.*
> — [`fvk/SPEC.md`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/SPEC.md#L20)

The intent specification turns "don't break entities" into a precise source-span
contract that any trim must satisfy — quoting the decisive clause:

> *"A source entity that decodes entirely to trailing punctuation moves as a whole
> source entity into the trail."*
> — [`fvk/SPEC.md`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/SPEC.md#L42)

The code audit then checks the V1 (baseline) source against that contract and
finds the violation by **construction, not observation** — `&#33;` is exactly the
shape the contract names but baseline's count-based slice mishandles. That is
discharged into a formal obligation:

> **O-005: Entity-encoded punctuation moves as a whole source span.** *If the
> trailing source suffix begins at an `&`, `html.unescape(suffix)` is non-empty,
> and every unescaped character of that suffix is in `TRAILING_PUNCTUATION_CHARS`,
> the whole source suffix must move to `trail`* — *`google.com/&#33;` keeps
> `google.com/` and moves `&#33;`.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/PROOF_OBLIGATIONS.md#L58)

This is the crux of FVK's value here: the residual bug was located by reasoning
over the invariant. The issue says "preserve the entity"; FVK generalizes that to
*every* trailing-suffix shape and the audit shows entity-**encoded** punctuation
(distinct from entity-**preceded** punctuation, which baseline did fix) is a
second shape the count-based slice gets wrong.

## 4. From formal output to the fix

The FVK arm's repair is iterative, and the artifacts record the exact step where
the formalism changed the patch. The audit explicitly refused to confirm V1
unchanged:

> *"Do not keep V1 unchanged. FVK finding F-002 showed that V1 still violated
> proof obligations O-004 and O-005 when trailing punctuation was encoded as an
> HTML entity. V2 replaces the count-only source slice with source-span
> trimming."*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/ITERATION_GUIDANCE.md#L7)

The decision log records the resulting code change and ties it back to the
finding and obligations:

> **D-001: Replace V1 count-only slicing with source-span trimming.** *Finding:
> F-002. Proof obligations: O-004 and O-005. … V2 change: inside
> `trim_punctuation()`, the new loop first checks whether the source suffix
> beginning at the last `&` unescapes entirely to trailing punctuation. If it
> does, V2 moves that whole suffix to `trail`.*
> — [`reports/fvk_notes.md`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/reports/fvk_notes.md#L13)

The causal chain is fully on the record:

```
SPEC I-004  ->  intent contract: whole-entity-punctuation must move as a source span (SPEC.md#L42)
            ->  F-002 (V1 audit: count slice breaks entity-encoded punctuation)
            ->  O-005  (obligation: move the whole &#33; source span)
            ->  ITERATION_GUIDANCE / D-001  ->  V2 patch
```

The [V2 patch](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/solutions/solution_fvk.patch)
replaces the single count-based slice with a `while` loop that, on each step,
moves a whole trailing entity span when it decodes entirely to punctuation, and
otherwise falls back to a literal-punctuation run:

```python
while punctuation_count:
    amp = middle.rfind('&')
    if amp >= 0:
        potential_entity = middle[amp:]
        escaped = html.unescape(potential_entity)
        if (escaped != potential_entity and escaped and
                all(char in TRAILING_PUNCTUATION_CHARS for char in escaped)):
            trail = potential_entity + trail
            middle = middle[:amp]
            punctuation_count -= len(escaped)
            continue
    punctuation = min(
        punctuation_count,
        len(middle) - len(middle.rstrip(TRAILING_PUNCTUATION_CHARS)),
    ) or 1
    trail = middle[-punctuation:] + trail
    middle = middle[:-punctuation]
    punctuation_count -= punctuation
```

The `V1 -> V2` transition was driven by `F-002`/`O-005`, **not** by a new failing
test: the public suite (`test_urlize`, `test_urlize_unchanged_inputs`) passes for
both arms and contains no `&#33;`-style case, so the residual defect is
unobservable through the harness and was caught only by the source audit.

## 5. Verification

**Evidence tier: source-and-artifact reviewed; not executed.** No
`enhanced_tests/_proof` RED/GREEN reports exist for this instance, and the FVK
session ran under a no-execution policy
([`prompts/fvk.md`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/prompts/fvk.md#L26):
*"No execution environment exists: do not attempt to run tests, Python, or K
framework tooling"*). What was inspected:

- The two patches (byte-different): baseline's single count-based slice vs. FVK's
  entity-aware `while` loop, confirming a real code delta rather than a
  formal-confirmation no-op.
- The official SWE-bench resolution reports — both arms
  [PASS](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/eval/baseline.report.json)
  the identical `FAIL_TO_PASS` + `PASS_TO_PASS` set, which establishes only that
  FVK did not regress the public behavior; it does **not** exercise the
  entity-encoded case.
- The constructed proof sketch
  ([`fvk/PROOF.md`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/PROOF.md#L22))
  reasoning through the entity path on `google.com/&#33;` and the literal path on
  the reported `google.com/?q=1&lt!`.

The residual-defect behavior below is **reasoned from the source**, not executed
on the harness:

| Input | original / baseline | **fvk** |
|---|---|---|
| `google.com/&#33;` (`&#33;` = `!`) | `middle="google.com/&#33"`, `trail=";"` — entity broken | `middle="google.com/"`, `trail="&#33;"` — whole entity moved |
| `google.com/?q=1&lt!` (reported) | fixed by baseline | unchanged: keeps `&lt`, moves `!` |

**Comparison to the human oracle.** The gold patch is not available for this
(non-curated) instance, so no line-level diff is possible; per the FVK audit the
gold/baseline fix targets the reported literal-punctuation case and does not
address entity-encoded trailing punctuation (finding
[F-002](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/FINDINGS.md#L21)).

## 6. Boundaries & honesty

- **Severity: Medium.** Valid text input can produce wrong **user-visible** linked
  text, which is more than cosmetic, but the trigger breadth is narrow — it fires
  only when a URL's *trailing* character is written as an HTML entity that decodes
  to punctuation (`&#33;`, `&semi;`). That is an uncommon authoring pattern, so the
  defect is genuinely user-facing but limited in reach — hence Medium, not High.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-urlize.k`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/mini-urlize.k),
  [`urlize-trim-spec.k`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/urlize-trim-spec.k))
  and the `kompile`/`kast`/`kprove` commands were *written but never run* — the
  FVK docs say so explicitly
  ([`fvk/PROOF.md`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/PROOF.md#L3),
  obligation
  [O-009](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/PROOF_OBLIGATIONS.md#L113),
  finding
  [F-004](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/FINDINGS.md#L55)).
  We therefore claim **proof-structured reasoning** (a source-span contract with
  obligations discharged by construction), **not a machine-checked proof**.
- **Attribution.** No harness test isolates the residual defect, so the §5
  before/after behavior is reasoned from the source, not observed; both arms'
  harness PASS shows only non-regression. The `V1 -> V2` ordering is documented
  across `FINDINGS.md`, `ITERATION_GUIDANCE.md`, and `fvk_notes.md`, and the raw
  trace can be timestamped from
  [`transcripts/fvk.jsonl.gz`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/transcripts/fvk.jsonl.gz)
  if a reviewer wants the full ordering.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro | [`prompts/fvk.md#L7`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/prompts/fvk.md#L7) |
| No-execution policy | [`prompts/fvk.md#L26`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/prompts/fvk.md#L26) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/solutions/solution_baseline.patch) |
| Baseline reasoning | [`reports/baseline_notes.md#L40`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/reports/baseline_notes.md#L40) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/solutions/solution_fvk.patch) |
| Intent I-004 (entity comment) | [`fvk/SPEC.md#L20`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/SPEC.md#L20) |
| Source-span contract clause | [`fvk/SPEC.md#L42`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/SPEC.md#L42) |
| Obligation O-005 | [`fvk/PROOF_OBLIGATIONS.md#L58`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/PROOF_OBLIGATIONS.md#L58) |
| Honesty gate O-009 | [`fvk/PROOF_OBLIGATIONS.md#L113`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/PROOF_OBLIGATIONS.md#L113) |
| Finding F-001 (reported bug) | [`fvk/FINDINGS.md#L6`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/FINDINGS.md#L6) |
| Finding F-002 (residual bug) | [`fvk/FINDINGS.md#L21`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/FINDINGS.md#L21) |
| Honesty note F-004 | [`fvk/FINDINGS.md#L55`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/FINDINGS.md#L55) |
| Iteration decision (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace D-001 | [`reports/fvk_notes.md#L13`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/reports/fvk_notes.md#L13) |
| Constructed proof sketch | [`fvk/PROOF.md#L22`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/PROOF.md#L22) |
| Constructed K core | [`fvk/mini-urlize.k`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/mini-urlize.k), [`fvk/urlize-trim-spec.k`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/fvk/urlize-trim-spec.k) |
| Official SWE-bench resolution | [`eval/baseline.report.json`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/eval/baseline.report.json), [`eval/fvk.report.json`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/eval/fvk.report.json) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified016-codex-XC-MINI-PRO-AHP-20260616T043623Z/django__django-14539/transcripts/fvk.jsonl.gz) |
