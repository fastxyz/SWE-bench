# pylint-dev__pylint-6386

## Summary

**Severity:** Low — baseline broadens startup preprocessing from `--`-only to any
single-dash argument but omits the `--` separator frame condition, so a literal
`-v` written *after* `--` is silently consumed as verbose mode; the trigger is a
narrow CLI syntax that almost no invocation uses.

Baseline and FVK both passed the official SWE-bench evaluation for this issue,
with **different** patches. To fix the reported bug (`-v` raising "expected one
argument"), baseline relaxed the preprocessor's gate from `argument.startswith("--")`
to `argument.startswith("-")`. That relaxation introduced a regression baseline
never noticed: once the preprocessor inspects every single-dash token, the `--`
end-of-options separator no longer stops it, so `-v` after `--` gets eaten. FVK
caught this by formalizing "`--` ends option processing" as an explicit obligation
and auditing the broadened loop against it — not by running a test (no execution
environment existed for this run).

| Arm | observable: `pylint mytest.py -- -v` preserves literal `-v` | Resolved |
|---|---|---|
| baseline | consumes `-v`, sets `Run.verbose = True` | no |
| gold (human oracle) | n/a — no gold file in this non-curated run | — |
| **fvk** | passes `-- -v` through untouched; `Run.verbose` unchanged | **yes** |

## 1. The issue and the real defect

The reported issue: pylint's short verbose option `-v` does not behave like
`--verbose`. `pylint mytest.py --verbose` works, but `pylint mytest.py -v` fails
with `argument --verbose/-v: expected one argument`, and `--help` advertises a
`VERBOSE` value for the option
([`prompts/fvk.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/prompts/fvk.md)).

The root cause has two parts. First, `--verbose` is handled by
`pylint.config.utils._preprocess_options`, which strips the option and sets
`Run.verbose` before normal config parsing; that loop only inspected arguments
beginning with `--`, so the short `-v` fell through to argparse. Second, the
registered argparse action for `verbose` is `_DoNothingAction` with no `nargs`
metadata, so argparse treated it as value-taking
([`reports/baseline_notes.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/reports/baseline_notes.md#L3)).
The original preprocessor gate:

```python
while i < len(args):
    argument = args[i]
    if not argument.startswith("--"):   # only long options inspected
        processed_args.append(argument)
        i += 1
        continue
```

The residual defect this case is about is **not** in the reported bug — it is in
how the gate was relaxed to fix it.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/solutions/solution_baseline.patch)
made three changes: registered `-v` as a preprocessable alias, relaxed the loop
gate from `--` to `-`, and set the verbose descriptor's argparse kwargs to
`{"nargs": 0}`:

```python
+    "-v": (False, _set_verbose_mode),
...
-        if not argument.startswith("--"):
+        if not argument.startswith("-"):
...
-                "kwargs": {},
+                "kwargs": {"nargs": 0},
```
([utils.py hunk](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/solutions/solution_baseline.patch#L18),
[base_options.py hunk](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/solutions/solution_baseline.patch#L31))

Baseline was not careless. Its notes show a deliberate, narrow scope: it rejected
a global `_DoNothingAction` change because the same action backs value-taking
options like `--rcfile`/`--output`, and called the direct `-v` alias "the
smallest targeted change"
([`reports/baseline_notes.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/reports/baseline_notes.md#L31)).

But its own description of the change is exactly where it stopped one step short:
it "allowed the preprocessor to inspect single-dash options"
([`reports/baseline_notes.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/reports/baseline_notes.md#L7))
without re-checking that the loop still honored the `--` end-of-options separator.
Before the change, `--` (which does not start with `--`... it equals `--`, so it
*did* match the old `startswith("--")` gate and was consumed/handled as a long
option, then any following `-v` did **not** match `startswith("--")` and passed
through). After relaxing to `startswith("-")`, the trailing `-v` now matches the
gate and is preprocessed as verbose. The unmet obligation: **`--` must terminate
preprocessing**, which the broadened loop no longer guaranteed.

## 3. How FVK formally captured the gap

FVK started from an intent spec that lifts the issue's command-line behavior into
named obligations rather than reasoning only from the reported symptom. The
decisive intent item is about the separator, which the issue never mentions:

> **I5. The `--` argument separator stops option preprocessing.** *Obligation:
> once `_preprocess_options` sees `--`, the separator and all following arguments
> must pass through untouched; in particular, `-v` after `--` must not enable
> verbose mode.*
> — [`fvk/INTENT_SPEC.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/INTENT_SPEC.md#L33)

That intent is grounded in a concrete code/convention fact in the evidence
ledger, derived by source audit (`pylint.__init__` documents `argv` as ordinary
command-line input), not by the reported test:

> **E5** — `repo/pylint/__init__.py`: *"`argv` can be a sequence of strings
> normally supplied as arguments on the command line"* → *Default command-line
> argument conventions apply unless contradicted. Encodes `--` separator frame in
> PO4, C4.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/PUBLIC_EVIDENCE_LEDGER.md#L11)

Which is discharged into a formal obligation that the V1 (baseline-equivalent)
loop must satisfy:

> **PO4: Separator frame.** *Claim: if the current argument is `"--"`,
> `_preprocess_options` appends the separator and the rest of the input to
> `processed_args` and stops; no callbacks are run for following tokens. Why:
> discharges F3 and preserves normal command-line separator behavior after
> broadening preprocessing to single-dash aliases.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/PROOF_OBLIGATIONS.md#L29)

This is the crux: the gap was located by **reasoning about a frame condition the
relaxation could break**, not by observing a failing case. The issue only asks
for `-v` parity; FVK's audit notes that broadening the gate from `--` to `-`
changes the loop's domain to include the post-`--` region, and PO4 is the
obligation that domain change must not violate.

## 4. From formal output to the fix

The finding that ties the obligation to a concrete defect in the V1 code is F3,
produced by static (symbolic) audit since no execution was permitted:

> **F3: V1 consumed short verbose after the `--` separator.** Input: `["--", "-v"]`.
> *Observed in V1 by static symbolic execution: `_preprocess_options` appended
> `"--"` as an unknown argument, then continued scanning and consumed `"-v"` as
> verbose. Result: output `["--"]`, `Run.verbose = True`.* … *Resolution: V2 adds
> an explicit separator guard that extends `processed_args` with `args[i:]` and
> breaks before further preprocessing.*
> — [`fvk/FINDINGS.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/FINDINGS.md#L29)

The iteration guidance converts F3 + PO4 into an instruction for the next code
state — keep V1's verbose fixes, add the guard:

> *"FVK Finding F3 exposed a frame-condition issue introduced by the V1
> broadening from long-only preprocessing to single-dash preprocessing: `-v`
> after `--` would be consumed as verbose. V2 keeps the V1 fixes for F1 and F2
> and adds the separator guard required by PO4."*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/ITERATION_GUIDANCE.md#L7)

The decision log records the resulting code change and its provenance:

> *"Added a V2 separator guard in `_preprocess_options`. This is justified by F3
> and PO4: after V1 started inspecting single-dash arguments, `["--", "-v"]`
> would consume `-v` as verbose even though `--` should end option preprocessing.
> The guard appends the separator and all following arguments unchanged, then
> stops early preprocessing."*
> — [`reports/fvk_notes.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/reports/fvk_notes.md#L13)

The causal chain is fully on the record:

```
INTENT_SPEC I5  ->  E5 (audit: argv is ordinary CLI input; `--` is a separator)
                ->  PO4 (obligation: `--` terminates preprocessing)
                ->  F3  (V1 audit: broadened loop eats `-v` after `--`)
                ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 separator guard
```

The resulting [FVK patch](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/solutions/solution_fvk.patch)
is byte-identical to baseline except for the added guard inside the loop:

```python
+        if argument == "--":
+            processed_args.extend(args[i:])
+            break
         if not argument.startswith("-"):
```
([fvk patch hunk](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/solutions/solution_fvk.patch#L18))

The `V1 -> V2` transition was driven by the **formal finding F3 / obligation PO4**,
explicitly **not** by a new test: the run prohibited running tests, Python, or K
tooling, and the iteration guidance only *suggests* a `-- -v` test for a future
test-editing pass rather than acting on a test result
([`fvk/ITERATION_GUIDANCE.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/ITERATION_GUIDANCE.md#L19)).

## 5. Verification

**Tier 3 — source-and-artifact reviewed; not executed.** This is a non-curated
run with no harness proof reports and no executed demonstration. The verification
basis is the patch diff plus the FVK artifacts, inspected directly:

- The exact `diff solution_baseline.patch solution_fvk.patch` shows the only
  delta is the three added lines of the separator guard
  ([fvk patch](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/solutions/solution_fvk.patch#L18)),
  on top of the shared `-v` alias, the `startswith("-")` relaxation, and the
  `nargs: 0` metadata fix. This confirms the residual-defect story: the FVK arm
  ships the same verbose fix as baseline plus the missing frame condition.
- The defect mechanism is reconstructed from the artifacts, not run: F3 records
  the V1 behavior on `["--", "-v"]` as `output ["--"], Run.verbose = True`
  ([`fvk/FINDINGS.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/FINDINGS.md#L29)),
  and proof claim C4 (SEPARATOR-FRAME) models the V2 guard rewriting the
  separator case directly to `done` without recursing into the following token
  ([`fvk/PROOF.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/PROOF.md#L37)).
- No gold/upstream comparison link exists for this non-curated instance. The
  gold-comparison prose is therefore omitted rather than asserted.

Both arms passed the official SWE-bench evaluation for the *reported* issue; the
post-`--` regression is outside the official hidden tests, so the harness does
not distinguish the two arms here. The FVK value claim rests on the inspected
artifact chain above, not on a RED→GREEN harness result.

## 6. Boundaries & honesty

- **Severity: Low (carried forward, not re-derived).** The trigger is a narrow
  CLI syntax: a literal `-v` written *after* the `--` end-of-options separator,
  e.g. `pylint mytest.py -- -v`. Realistic invocations rarely place option-like
  tokens after `--`, and the consequence is only that verbose mode turns on
  unexpectedly — no crash, no data loss. The value demonstrated is **detection
  power** (catching a frame-condition regression introduced by a correct-looking
  relaxation), not impact magnitude.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`cli-verbose-spec.k`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/cli-verbose-spec.k),
  [`mini-cli.k`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/mini-cli.k))
  and the `kompile`/`kprove` commands were written but never run; the run had no
  execution environment, and the artifacts say so explicitly via the honesty gate
  ([PO8](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/PROOF_OBLIGATIONS.md#L61),
  [`fvk/PROOF.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/PROOF.md#L3)).
  We therefore claim **proof-structured reasoning**, not a machine-checked proof.
- **Attribution.** The patch comparison was verified directly (the only delta is
  the separator guard), so the code story is observed, not reconstructed. The
  *defect behavior* on `["--", "-v"]`, however, is asserted by FVK's static
  symbolic audit (F3) and was not executed; a confirming `-- -v` test is only
  recommended for a future pass. No discrepancy was found between the existing
  evidence doc and the run artifacts — the doc's claim that baseline "could also
  consume `-v` after `--`" matches F3, PO4, and the patch diff exactly.

## Artifact map

| Claim | Source |
|---|---|
| Issue text (`-v` expects an argument; `VERBOSE` metavar) | [`prompts/fvk.md`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/prompts/fvk.md) |
| Root cause (`--`-only preprocessing; `_DoNothingAction` no nargs) | [`reports/baseline_notes.md#L3`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/reports/baseline_notes.md#L3) |
| Baseline patch (3 changes) | [`solutions/solution_baseline.patch`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/solutions/solution_baseline.patch#L18) |
| Baseline reasoning (narrow scope, "smallest targeted change") | [`reports/baseline_notes.md#L31`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/reports/baseline_notes.md#L31) |
| Baseline broadened to single-dash inspection | [`reports/baseline_notes.md#L7`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/reports/baseline_notes.md#L7) |
| Intent I5 (`--` stops preprocessing) | [`fvk/INTENT_SPEC.md#L33`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/INTENT_SPEC.md#L33) |
| Evidence E5 (`argv` is ordinary CLI input) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L11`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/PUBLIC_EVIDENCE_LEDGER.md#L11) |
| Obligation PO4 (separator frame) | [`fvk/PROOF_OBLIGATIONS.md#L29`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/PROOF_OBLIGATIONS.md#L29) |
| Finding F3 (V1 eats `-v` after `--`) | [`fvk/FINDINGS.md#L29`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/FINDINGS.md#L29) |
| Iteration guidance (add separator guard) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace (V2 guard provenance) | [`reports/fvk_notes.md#L13`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/reports/fvk_notes.md#L13) |
| FVK patch (separator guard hunk) | [`solutions/solution_fvk.patch#L18`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/solutions/solution_fvk.patch#L18) |
| Proof claim C4 (SEPARATOR-FRAME) | [`fvk/PROOF.md#L37`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/PROOF.md#L37) |
| Honesty gate (constructed, not run) | [`fvk/PROOF_OBLIGATIONS.md#L61`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/PROOF_OBLIGATIONS.md#L61), [`fvk/PROOF.md#L3`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/PROOF.md#L3) |
| Constructed K core | [`fvk/cli-verbose-spec.k`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/cli-verbose-spec.k), [`fvk/mini-cli.k`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/fvk/mini-cli.k) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified033-codex-archlinux-20260616T154504Z/pylint-dev__pylint-6386/transcripts/fvk.jsonl.gz) |
