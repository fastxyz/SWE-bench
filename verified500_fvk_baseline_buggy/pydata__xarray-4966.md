# pydata__xarray-4966

## Summary

**Severity:** High — baseline recognizes only the *string* `_Unsigned="false"`
marker, so an OPeNDAP/pydap variable whose `_Unsigned` attribute arrives as the
Python boolean `False` is left unconverted and its byte data is silently decoded
with the wrong signedness (`128`/`255` instead of `-128`/`-1`).

Baseline and FVK both passed the official SWE-bench evaluation for this issue,
with **different** patches. Baseline correctly extended `UnsignedIntegerCoder`
to convert unsigned-byte data to signed under the *string* marker `"false"`, but
its `unsigned == "false"` comparison is false for the boolean `False` — exactly
the spelling the issue text uses (`if .kind == "u" and unsigned == False`). FVK
located this residual gap by **lifting the issue into a marker-classification
obligation and auditing the comparison against it**, not by running a new test,
and widened the decode predicate to accept both the string and the boolean.

| Arm | OPeNDAP byte decode with `_Unsigned=False` (boolean) | Resolved |
|---|---|---|
| baseline | leaves `[128, 255]` unsigned — **wrong signedness** | no |
| gold (human oracle) | not available for this run (non-curated) | — |
| **fvk** | converts to signed `[-128, -1]` | **yes** |

## 1. The issue and the real defect

The issue concerns CF `_Unsigned` decoding for OPeNDAP data served through
pydap. netCDF3 stores only signed bytes and marks unsigned semantics with
`_Unsigned=True`; OPeNDAP stores only unsigned bytes and marks signed semantics
with `_Unsigned=False`. For the pydap case, byte values `128` and `255` must
decode to the signed values `-128` and `-1`, but xarray instead emitted a
`SerializationWarning` and left the values uninterpreted. The decoder under
audit is
[`UnsignedIntegerCoder.decode`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/SPEC.md#L6)
in `xarray/coding/variables.py`, which runs before `CFMaskCoder` /
`CFScaleOffsetCoder` when `mask_and_scale=True`
([problem statement](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/prompts/fvk.md#L2)).

The load-bearing detail is the **spelling of the marker**. The issue's suggested
condition is written with the Python boolean, not a string:

> *E3 — "`if .kind == "u" and unsigned == False`" → The false-marker case must
> include explicit boolean `False`, not only string `"false"`.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/PUBLIC_EVIDENCE_LEDGER.md#L9)

Because `"false" == False` is `False` in Python, a decoder that only checks the
string marker silently does nothing for a boolean-valued attribute and decodes
the bytes with the wrong signedness — a data-corruption defect, not a warning.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/solutions/solution_baseline.patch)
did the substantive work the issue asked for: it broadened the candidate guard
from `data.dtype.kind == "i"` to `data.dtype.kind in ("i", "u")` and added the
symmetric branch that converts unsigned data to the matching signed dtype, also
recasting `_FillValue` before masking:

```python
if data.dtype.kind in ("i", "u"):
    if unsigned == "true" and data.dtype.kind == "i":
        new_dtype = np.dtype("u%s" % data.dtype.itemsize)
    elif unsigned == "false" and data.dtype.kind == "u":
        new_dtype = np.dtype("i%s" % data.dtype.itemsize)
    else:
        new_dtype = None
```

Baseline was not careless about marker breadth — it made a **conscious, narrow**
choice and recorded it:

> *"The `_Unsigned` attribute values relevant to this code path are the existing
> string values `"true"` and `"false"` … I did not broaden accepted truthy or
> falsy forms; values other than those strings are still not converted by this
> coder."*
> — [`reports/baseline_notes.md`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/reports/baseline_notes.md#L27)

That reasoning is defensible against *generic* truthiness — accepting `0`, `1`,
`""`, or arbitrary objects as markers would be a bug. But it conflated "don't
accept arbitrary truthy/falsy values" with "accept only the strings," and so it
excluded the **one** non-string value the issue explicitly names: the boolean
`False`. The unmet obligation is precise marker classification — accept exactly
`{"true", True}` for unsigned and `{"false", False}` for signed — which baseline
left at `{"true"}` / `{"false"}`.

## 3. How FVK formally captured the gap

FVK started from intent, not the symptom. The intent spec enumerates the
accepted marker set as a closed equivalence class — strings **and** the two
named booleans, excluding generic truthiness:

> *"The accepted explicit markers are the existing string convention values
> `"true"` and `"false"` plus the explicit Python boolean values `True` and
> `False` named by the issue prose. Arbitrary truthy or falsy values are not
> accepted."*
> — [`fvk/INTENT_SPEC.md`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/INTENT_SPEC.md#L24)

That intent is pinned to a concrete code fact by the evidence ledger — the issue
prose itself supplies the boolean spelling, so the marker domain is set by the
**reported condition**, not by guesswork:

> *E3 — "`if .kind == "u" and unsigned == False`" → The false-marker case must
> include explicit boolean `False`, not only string `"false"`. Status: V1 gap;
> V2 code edit.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/PUBLIC_EVIDENCE_LEDGER.md#L9)

These discharge into a formal obligation on the classifier predicate:

> **PO1: Marker classification** — *unsigned marker iff `_Unsigned == "true"` or
> `_Unsigned is True`; signed marker iff `_Unsigned == "false"` or
> `_Unsigned is False`. Arbitrary truthy or falsy values must not trigger
> conversion.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/PROOF_OBLIGATIONS.md#L5)

This is the crux: PO1 is an obligation over the *comparison itself*, evaluated by
static inspection of the predicate against the four-case marker domain
(`CLAIM-SIGNED-STRING-TRUE`, `CLAIM-SIGNED-BOOL-TRUE`,
`CLAIM-UNSIGNED-STRING-FALSE`, `CLAIM-UNSIGNED-BOOL-FALSE` in
[`fvk/FORMAL_SPEC_ENGLISH.md`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/FORMAL_SPEC_ENGLISH.md#L12)).
Reading baseline's `unsigned == "false"` against the `{"false", False}` domain
shows the boolean case is unhandled — the defect is found by reasoning over the
predicate, not by exercising it.

## 4. From formal output to the fix

The audit of the V1 (baseline-equivalent) tree against PO1 produced the finding
that drives the patch:

> **F1: V1 omitted explicit boolean false marker.** *Observed in V1 by static
> inspection: `data.dtype.kind in ("i", "u")` is true, but `unsigned == "false"`
> is false for boolean `False`; `new_dtype` remains `None`, so values stay
> unsigned. Expected: `_Unsigned=False` means unsigned OPeNDAP bytes represent
> signed byte data, so values decode to `[-128, -1]`.*
> — [`fvk/FINDINGS.md`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/FINDINGS.md#L6)

The iteration guidance turns the finding into the next-revision instruction,
scoped to decode only:

> *"V1 … only accepted string `"false"` for the OPeNDAP signed-byte marker. V2
> updates `UnsignedIntegerCoder.decode` to accept explicit boolean `False` and
> explicit boolean `True` in addition to the existing string markers."*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/ITERATION_GUIDANCE.md#L7)

And the decision log records the exact code form and its provenance, including
the deliberate refusal of generic truthiness:

> *"V2 extends `UnsignedIntegerCoder.decode` marker recognition from string-only
> checks to explicit marker checks: unsigned marker: `unsigned == "true" or
> unsigned is True`; signed marker: `unsigned == "false" or unsigned is False`.
> This change is justified by `fvk/FINDINGS.md` F1 and proof obligations PO1 and
> PO2."*
> — [`reports/fvk_notes.md`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/reports/fvk_notes.md#L7)

The causal chain is fully on the record:

```
INTENT_SPEC §6 (marker set = strings + named booleans)
    ->  E3 (issue writes `unsigned == False`, not `"false"`)
    ->  PO1 (obligation: classify {"false", False} / {"true", True})
    ->  F1  (V1 audit: `unsigned == "false"` misses boolean False)
    ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The resulting
[fvk patch](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/solutions/solution_fvk.patch)
replaces the inline string comparisons with named predicates that admit both
spellings:

```python
is_unsigned = unsigned == "true" or unsigned is True
is_signed = unsigned == "false" or unsigned is False

if is_unsigned and data.dtype.kind == "i":
    new_dtype = np.dtype("u%s" % data.dtype.itemsize)
elif is_signed and data.dtype.kind == "u":
    new_dtype = np.dtype("i%s" % data.dtype.itemsize)
```

The `is True` / `is False` identity checks (rather than `==`) keep `0`/`1` and
other truthy/falsy values out of the marker class, satisfying PO1's exclusion
clause. The `V1 -> V2` transition was driven by the formal finding **F1/PO1**,
**not** by a new failing test — the run had no execution environment and no test
was added or run (see §5).

## 5. Verification

**Tier 3 — source-and-artifact reviewed; not executed.** This run is
non-curated: there is no `verified500_analysis` directory, no harness RED/GREEN
report, and no gold patch. The FVK task ran under an explicit constraint that
forbade running tests, Python, or K tooling
([`prompts/fvk.md`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/prompts/fvk.md#L27)),
so there is no executed behavioral demonstration to reuse either.

What was inspected to support the claims above:

- The two patches were diffed directly. Baseline
  ([`solution_baseline.patch`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/solutions/solution_baseline.patch))
  guards on `unsigned == "true"` / `unsigned == "false"`; FVK
  ([`solution_fvk.patch`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/solutions/solution_fvk.patch))
  adds `is_unsigned = unsigned == "true" or unsigned is True` and
  `is_signed = unsigned == "false" or unsigned is False`. The delta is exactly the
  boolean-marker widening claimed.
- The expected decode values (`128 -> -128`, `255 -> -1`) are stated in the
  intent spec
  ([`fvk/INTENT_SPEC.md`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/INTENT_SPEC.md#L14))
  and the cast-function paraphrase
  ([`fvk/FORMAL_SPEC_ENGLISH.md`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/FORMAL_SPEC_ENGLISH.md#L44)),
  and follow from NumPy two's-complement reinterpretation; they were not run.
- Both arms passed the official SWE-bench evaluation per the existing case
  record; that evaluation harness output is not part of this run's artifacts.

The recommended regression tests — `np.uint8([128, 255])` with both
`_Unsigned="false"` and `_Unsigned=False`, fill-value recasting, and the
non-integer warning — are written into
[`fvk/ITERATION_GUIDANCE.md`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/ITERATION_GUIDANCE.md#L17)
but were left for a future environment.

## 6. Boundaries & honesty

- **Severity: High.** The residual defect changes decoded *data values*, not a
  warning or a message: under a boolean `_Unsigned=False`, every byte is read
  with inverted signedness (`128 <-> -128`, `255 <-> -1`). The trigger is narrow
  in form (only the boolean spelling of the marker, only integer arrays) but the
  blast radius per occurrence is large — silent, unflagged corruption of
  scientific array data with no exception to alert the user. That value-corruption
  severity is why this rates High despite the narrow trigger.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-unsigned-coder.k`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/mini-unsigned-coder.k),
  [`unsigned-integer-coder-spec.k`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/unsigned-integer-coder-spec.k))
  and the `kompile`/`kast`/`kprove` commands were **written but never run** — the
  artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/PROOF.md#L3),
  [finding F5](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/FINDINGS.md#L82)).
  We therefore claim **proof-structured reasoning** (a spec with obligations
  discharged by construction and static predicate inspection), **not** a
  machine-checked proof.
- **Correction recorded.** The earlier case note and `baseline_notes.md` describe
  the *original* (pre-patch) decoder as recognizing "only signed integer arrays."
  That is the original code; the **baseline patch under evaluation already**
  extended the guard to `("i", "u")` and added the `_Unsigned=="false"` signed
  branch. The genuine residual gap is therefore *not* "unsigned data is ignored"
  but specifically "the boolean `False` marker is not recognized." §1/§2 above are
  written against the actual baseline patch; the FVK finding F1 agrees.
- **Attribution caveats.** This is a non-curated run, so there is no independent
  harness verdict, no gold patch to compare against, and no executed
  demonstration in these artifacts. The fix's correctness rests on (a) the patch
  diff matching the obligation, (b) the cited NumPy cast semantics, and (c) the
  reported (but not re-run here) SWE-bench pass for both arms. The decision
  ordering (`F1 -> PO1 -> V2`) is reconstructed from the FVK artifacts; the raw
  trace is in
  [`transcripts/fvk.jsonl.gz`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/transcripts/fvk.jsonl.gz)
  if a reviewer wants the timestamped sequence.

## Artifact map

| Claim | Source |
|---|---|
| Unit under audit | [`fvk/SPEC.md#L6`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/SPEC.md#L6) |
| Problem statement (non-curated) | [`prompts/fvk.md#L2`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/prompts/fvk.md#L2) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/solutions/solution_baseline.patch) |
| Baseline narrow-marker assumption | [`reports/baseline_notes.md#L27`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/reports/baseline_notes.md#L27) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/solutions/solution_fvk.patch) |
| Intent: accepted marker set | [`fvk/INTENT_SPEC.md#L24`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/INTENT_SPEC.md#L24) |
| Expected decode values 128→-128 | [`fvk/INTENT_SPEC.md#L14`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/INTENT_SPEC.md#L14) |
| Evidence E3 (boolean marker) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L9`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/PUBLIC_EVIDENCE_LEDGER.md#L9) |
| Obligation PO1 (classification) | [`fvk/PROOF_OBLIGATIONS.md#L5`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/PROOF_OBLIGATIONS.md#L5) |
| Marker claims paraphrase | [`fvk/FORMAL_SPEC_ENGLISH.md#L12`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/FORMAL_SPEC_ENGLISH.md#L12) |
| Cast-function semantics | [`fvk/FORMAL_SPEC_ENGLISH.md#L44`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/FORMAL_SPEC_ENGLISH.md#L44) |
| Finding F1 (boolean gap) | [`fvk/FINDINGS.md#L6`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/FINDINGS.md#L6) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/ITERATION_GUIDANCE.md#L7) |
| Recommended regression tests | [`fvk/ITERATION_GUIDANCE.md#L17`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/ITERATION_GUIDANCE.md#L17) |
| Decision trace (V2 predicate) | [`reports/fvk_notes.md#L7`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/reports/fvk_notes.md#L7) |
| Constructed K core | [`fvk/mini-unsigned-coder.k`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/mini-unsigned-coder.k), [`fvk/unsigned-integer-coder-spec.k`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/unsigned-integer-coder-spec.k) |
| Proof not machine-checked | [`fvk/PROOF.md#L3`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/PROOF.md#L3), [`fvk/FINDINGS.md#L82`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/fvk/FINDINGS.md#L82) |
| Raw model traces | [`transcripts/fvk.jsonl.gz`](../results/verified032-codex-archlinux-20260616T145521Z/pydata__xarray-4966/transcripts/fvk.jsonl.gz) |
