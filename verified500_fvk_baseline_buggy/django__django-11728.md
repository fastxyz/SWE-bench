# django__django-11728

## Summary

**Severity:** Low — baseline can reconstruct the wrong admindocs regex
simplification for multiple, adjacent, or nested unnamed groups, but the defect
is confined to `replace_unnamed_groups()` and only surfaces in admindocs URL
documentation.

Baseline and FVK both passed the official SWE-bench evaluation for this issue,
with **different** patches. Baseline fixed the reported trailing-group bug in
both helpers; the FVK arm kept that fix and additionally reworked the
`replace_unnamed_groups()` span filter and reconstruction loop, which baseline
left in a state that duplicates path text for multiple unnamed groups and
mis-selects adjacent or nested spans. FVK located the residual by **formalizing
the helper's plural contract as an invariant** over every selected span, not by
running more tests.

| Arm | Multiple/adjacent/nested unnamed groups in `replace_unnamed_groups()` | Resolved |
|---|---|---|
| baseline | trailing-group fix only; reconstruction/filter unchanged | no |
| gold (human oracle) | (no gold artifact retained for this run) | — |
| **fvk** | moving-cursor reconstruction + `start >= prev_end` span filter | **yes** |

## 1. The issue and the real defect

The task is the admindocs regex simplifier: `simplify_regex()` turns a URL regex
fragment into a readable path, replacing named groups with `<name>` and unnamed
groups with `<var>`. The problem statement for this run is the FVK continuation
prompt and its referenced `benchmark/PROBLEM.md`
([`prompts/fvk.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/prompts/fvk.md#L12)).
The reported bug is that `replace_named_groups()` *"fails to replace the final
named group if the urlpattern passed in is missing a trailing `/`"*
([`PUBLIC_EVIDENCE_LEDGER.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/PUBLIC_EVIDENCE_LEDGER.md#L6)),
with the public hint that a *"similar change should be made in
`replace_unnamed_groups()`"*
([`PUBLIC_EVIDENCE_LEDGER.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/PUBLIC_EVIDENCE_LEDGER.md#L25)).

The user-facing observable is the simplified URL string shown in admindocs.
The original scanners only tested the balanced-bracket completion condition at
the *start* of the next loop iteration, so a group whose closing `)` is the last
character of the pattern is never recorded
([`reports/baseline_notes.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/reports/baseline_notes.md#L7)).

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/solutions/solution_baseline.patch)
moved the completion check to *after* the current character is processed and
extended the recorded slice through the closing parenthesis, in **both**
`replace_named_groups()` and `replace_unnamed_groups()`:

```python
+            if unmatched_open_brackets == 0:
+                group_indices.append((start, start + 1 + idx + 1))
+                break
```

That is exactly what the reported issue and the public hint asked for, and the
baseline notes state the choice deliberately:

> *"I kept the existing parsing approach and only fixed the off-by-one
> completion behavior. Replacing the scanner with a different parser would be
> broader than the reported issue requires."*
> — [`reports/baseline_notes.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/reports/baseline_notes.md#L31)

Baseline was not careless: it fixed the recording bug and left the *rest* of
`replace_unnamed_groups()` — the outermost-span filter and the reconstruction
loop — untouched. But those two pieces carry their own correctness obligation
once more than one unnamed group can reach them, and baseline left that
obligation unmet.

## 3. How FVK formally captured the gap

FVK started from the helper's contract, not the single reported symptom. The
decisive intent item generalizes the unnamed-group requirement beyond the
trailing case:

> *"For unnamed groups, the helper's plural contract and examples require all
> outermost unnamed capture groups to be replaced, not only the first one. Text
> between groups must be preserved exactly once, and nested groups inside an
> outer unnamed group must not produce additional `<var>` replacements …"*
> — [`INTENT_SPEC.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/INTENT_SPEC.md#L23)

The evidence ledger pins that intent to a concrete fact about the implementation
— derived from the docstring's plural wording and a source audit of the
reconstruction loop, **not** from any reported test:

> **E4 (helper docstring, plural unnamed groups):** *"all outermost unnamed
> groups in the verified pattern are replaced; the implementation must not
> duplicate text when more than one group exists."*
> — [`PUBLIC_EVIDENCE_LEDGER.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/PUBLIC_EVIDENCE_LEDGER.md#L34)

That fact discharges into two formal obligations on the parts baseline did not
touch. The span filter:

> **POB-U2:** *"A candidate span is selected exactly when no selected span is
> active over its start position: `prev_end is None or start >= prev_end`. …
> Adjacent spans with `start == prev_end` are selected. Nested spans with
> `start < prev_end` are skipped …"*
> — [`PROOF_OBLIGATIONS.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/PROOF_OBLIGATIONS.md#L49)

and the reconstruction loop:

> **POB-U3:** *"Appending `pattern[prev_end:start]` copies only the intervening
> original text. … V2 uses `prev_end = 0` and appends only the intervening slice
> plus `<var>` for each selected span, then appends the suffix."*
> — [`PROOF_OBLIGATIONS.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/PROOF_OBLIGATIONS.md#L70)

This is the crux: the residual was located by **reasoning about the plural
contract over every selected span**, not by observing a failing case. The issue
only asks for the trailing group; FVK lifts the docstring's "find unnamed groups
… replace them" into an invariant over the *list* of spans, and the obligations
expose that baseline's untouched filter and reconstruction loop violate it.

## 4. From formal output to the fix

The completeness audit against POB-U2/POB-U3 produced two findings on the code
baseline left alone.

- Reconstruction:

  > **F3: V1 left a reconstruction bug for multiple unnamed groups.** *"the
  > reconstruction loop appended `pattern[:start] + '<var>'` for every selected
  > group. That is only correct for the first selected span."*
  > — [`FINDINGS.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/FINDINGS.md#L30)

- Span filtering:

  > **F4: V1 left edge cases in unnamed outermost-span filtering.** *"the second
  > group was skipped because `start > prev_end` rejected adjacent spans … after
  > skipping a nested group, the old code updated `prev_end` to the skipped
  > nested span's end, allowing a later nested group … to be selected."*
  > — [`FINDINGS.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/FINDINGS.md#L44)

The iteration guidance turned those findings into concrete source changes:

> *"3. Change unnamed reconstruction to use a moving cursor. … 4. Change unnamed
> span filtering to keep only selected-span ends in `prev_end` and to allow
> adjacent spans."*
> — [`ITERATION_GUIDANCE.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/ITERATION_GUIDANCE.md#L15)

and the decision log records each change traced to its obligation:

> *"Decision: replace repeated `pattern[:start] + '<var>'` appends with a moving
> `prev_end` cursor … POB-U3 requires each non-group segment to be copied
> exactly once."*
> — [`reports/fvk_notes.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/reports/fvk_notes.md#L31)

The causal chain is fully on the record:

```
INTENT_SPEC item 4 (plural contract: all outermost groups, text once)
   ->  E4   (code audit: reconstruction appends pattern[:start] per group)
   ->  F3/F4 (V1 audit: duplicated prefix; adjacent/nested span mis-selection)
   ->  POB-U2 / POB-U3 (obligations: outermost spans; text copied once)
   ->  ITERATION_GUIDANCE 3/4 / fvk_notes  ->  V2 patch
```

The resulting [FVK patch](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/solutions/solution_fvk.patch)
rewrites both the filter and the reconstruction loop:

```python
     for start, end in group_indices:
-        if prev_end and start > prev_end or not prev_end:
+        if prev_end is None or start >= prev_end:
             group_start_end_indices.append((start, end))
-        prev_end = end
+            prev_end = end
...
-        final_pattern, prev_end = [], None
+        final_pattern, prev_end = [], 0
         for start, end in group_start_end_indices:
-            if prev_end:
-                final_pattern.append(pattern[prev_end:start])
-            final_pattern.append(pattern[:start] + '<var>')
+            final_pattern.append(pattern[prev_end:start])
+            final_pattern.append('<var>')
             prev_end = end
```

The `baseline -> fvk` transition was driven by `F3`/`F4` and obligations
`POB-U2`/`POB-U3`, **not** by a new failing test — the prompt forbade tests
entirely and none for these multi-group shapes exists in the visible suite
([`prompts/fvk.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/prompts/fvk.md#L26)).

## 5. Verification

**Tier 3 — source-and-artifact reviewed; not executed.** No harness RED/GREEN
report exists for this instance (it is not curated, and the FVK prompt forbade
running tests, Python, or K tooling
[`prompts/fvk.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/prompts/fvk.md#L26)).
The basis for the conclusion is review of:

- the two patches, confirmed to differ: the FVK patch keeps baseline's scanner
  fix and adds the `start >= prev_end` filter and moving-cursor reconstruction
  ([`solution_baseline.patch`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/solutions/solution_baseline.patch),
  [`solution_fvk.patch`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/solutions/solution_fvk.patch));
- the obligation→finding→decision chain in
  [`FINDINGS.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/FINDINGS.md#L30),
  [`PROOF_OBLIGATIONS.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/PROOF_OBLIGATIONS.md#L39),
  and [`reports/fvk_notes.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/reports/fvk_notes.md#L31);
- the constructed proof sketches for outermost filtering and reconstruction in
  [`PROOF.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/PROOF.md#L41),
  together with their worked input/output examples
  (`a/(\w+)/b/(\d+) -> /a/<var>/b/<var>`, adjacent `a/(\w+)(\d+) -> /a/<var><var>`,
  nested `a/((x)y(z)) -> /a/<var>`) in
  [`ITERATION_GUIDANCE.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/ITERATION_GUIDANCE.md#L28).

These worked examples are reasoning artifacts, not executed test output; there
is no RED/GREEN table to present for this case.

## 6. Boundaries & honesty

- **Severity: Low.** The residual triggers only on a specialized regex shape —
  *multiple, adjacent, or nested* unnamed capture groups reaching
  `replace_unnamed_groups()` — and only affects admindocs URL documentation
  strings, never request routing or stored data. A single unnamed group (the
  common case) renders correctly under baseline. The value shown here is
  detection completeness, not impact magnitude.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-regex-groups.k`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/mini-regex-groups.k),
  [`admindocs-regex-spec.k`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/admindocs-regex-spec.k))
  and the `kompile`/`kast`/`kprove` commands were *written but never run* — the
  FVK proof says so explicitly
  ([`PROOF.md`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/PROOF.md#L3)).
  We therefore claim **proof-structured reasoning** (a formal spec with
  obligations discharged by construction), **not** a machine-checked proof.
- **Attribution.** No gold patch was retained for this run, so the comparison to
  a human oracle is from prose only: the FVK arm's extra rework of the unnamed
  filter and reconstruction loop is beyond what the reported issue requested, but
  without the gold diff we cannot assert here whether the official fix touched the
  same lines. Both arms were marked resolved by the official evaluation, so the
  harness alone does not distinguish them; the distinction rests on the source
  review above.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, trailing-group bug, unnamed hint | [`prompts/fvk.md#L12`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/prompts/fvk.md#L12) |
| Root cause (next-iteration completion check) | [`reports/baseline_notes.md#L7`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/reports/baseline_notes.md#L7) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/solutions/solution_baseline.patch) |
| Baseline scoping rationale | [`reports/baseline_notes.md#L31`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/reports/baseline_notes.md#L31) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/solutions/solution_fvk.patch) |
| Intent (plural contract) | [`INTENT_SPEC.md#L23`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/INTENT_SPEC.md#L23) |
| Evidence E4 | [`PUBLIC_EVIDENCE_LEDGER.md#L34`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/PUBLIC_EVIDENCE_LEDGER.md#L34) |
| Obligation POB-U2 (span filter) | [`PROOF_OBLIGATIONS.md#L49`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/PROOF_OBLIGATIONS.md#L49) |
| Obligation POB-U3 (reconstruction) | [`PROOF_OBLIGATIONS.md#L70`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/PROOF_OBLIGATIONS.md#L70) |
| Finding F3 (duplicated prefix) | [`FINDINGS.md#L30`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/FINDINGS.md#L30) |
| Finding F4 (adjacent/nested span) | [`FINDINGS.md#L44`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/FINDINGS.md#L44) |
| Iteration instructions 3/4 | [`ITERATION_GUIDANCE.md#L15`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/ITERATION_GUIDANCE.md#L15) |
| Decision trace (reconstruction rework) | [`reports/fvk_notes.md#L31`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/reports/fvk_notes.md#L31) |
| Constructed proof (filtering, reconstruction) | [`PROOF.md#L41`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/PROOF.md#L41) |
| Worked input/output examples | [`ITERATION_GUIDANCE.md#L28`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/ITERATION_GUIDANCE.md#L28) |
| Proof status (not machine-checked) | [`PROOF.md#L3`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/PROOF.md#L3) |
| Constructed K core | [`mini-regex-groups.k`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/mini-regex-groups.k), [`admindocs-regex-spec.k`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/fvk/admindocs-regex-spec.k) |
| No-execution constraint | [`prompts/fvk.md#L26`](../results/verified006-codex-XC-MINI-PRO-AHP-20260615T190047Z/django__django-11728/prompts/fvk.md#L26) |
