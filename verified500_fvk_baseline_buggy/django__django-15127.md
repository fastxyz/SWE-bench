# django__django-15127

## Summary

**Severity:** Low — baseline refreshes `MESSAGE_TAGS` by *rebinding* the module
global `LEVEL_TAGS`, leaving any pre-existing direct reference to the original
mapping object stale; the residual only bites code that holds such a direct
reference, so the trigger is narrow.

Baseline's core fix is correct: it installs a `setting_changed` receiver so that
`Message.level_tag` stops returning `''` for levels supplied by an overridden
`MESSAGE_TAGS`, and the baseline patch passed the official SWE-bench evaluation.
The residual is purely in *how* the receiver refreshes: rebinding the global
fixes every future module-qualified lookup but not an already-exported reference
to the public mapping object. FVK located this by formalizing the issue's "stale
`LEVEL_TAGS`" wording as an object-identity obligation (PO-6) and narrowed V2 to
refresh the mapping in place (`clear()` + `update()`).

| Arm | `Message.level_tag` fixed under override; existing `LEVEL_TAGS` reference also refreshed | Resolved |
|---|---|---|
| baseline | `level_tag` fixed; but receiver rebinds the global, so a held reference stays stale | partial |
| gold (human oracle) | `level_tag` fixed; refresh scoped to the receiver | yes |
| **fvk** | `level_tag` fixed; receiver refreshes the mapping in place, preserving object identity | yes |

## 1. The issue and the real defect

The issue is *"`LEVEL_TAGS` not updated when using `@override_settings`"*: under
`override_settings(MESSAGE_TAGS=...)`, `Message.level_tag` keeps returning an
empty string for newly configured levels because the module constant was never
recomputed
([`prompts/fvk.md`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/prompts/fvk.md#L2)).
The evidence ledger records the two reported observables verbatim — *"LEVEL_TAGS
not updated when using @override_settings"*
([E1](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/PUBLIC_EVIDENCE_LEDGER.md#L7))
and *"Message.level_tag property results to be an empty string and not know the
new tags"*
([E2](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/PUBLIC_EVIDENCE_LEDGER.md#L8)).

The root cause is that `django.contrib.messages.storage.base.LEVEL_TAGS` is
computed once at import time from `utils.get_level_tags()` and never recomputed
after `override_settings()` sends Django's `setting_changed` signal, so
`Message.level_tag` reads stale tag data
([`reports/baseline_notes.md`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/reports/baseline_notes.md#L5)).
The user-facing observable is that a custom level (e.g. `50`) configured through
`MESSAGE_TAGS` renders as `''` instead of its tag.

## 2. Baseline's fix — and where it stopped

Baseline's diagnosis and the shape of its fix are correct. It adds a
`setting_changed` receiver in `storage.base` that rebuilds `LEVEL_TAGS` from
`utils.get_level_tags()` whenever `MESSAGE_TAGS` changes
([`solutions/solution_baseline.patch`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/solutions/solution_baseline.patch#L14)).
Its placement reasoning is deliberate, and it consciously rejected the broader
alternatives:

> *"I considered moving this into `django/test/signals.py`, but rejected that
> because the existing comment there says contrib-app-related receivers belong
> with the contrib app. … I considered replacing `LEVEL_TAGS` with a fresh
> `utils.get_level_tags()` call inside `Message.level_tag`, but rejected that
> because it would change the existing constant-based behavior for every lookup."*
> — [`reports/baseline_notes.md`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/reports/baseline_notes.md#L28)

That reasoning is sound, and for the reported symptom the fix works: after the
override, `base.LEVEL_TAGS` is rebound to the new effective mapping and
`Message.level_tag` reads the fresh global. The gap is in the refresh mechanism:
the receiver runs `global LEVEL_TAGS; LEVEL_TAGS = utils.get_level_tags()`
([baseline patch, receiver body](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/solutions/solution_baseline.patch#L17)).
Rebinding the name swaps in a *new* mapping object; the original object that any
prior `from ... import LEVEL_TAGS` or saved reference points to is left untouched
and stale. The unmet obligation is object-identity preservation: the issue names
`LEVEL_TAGS` itself as the stale state, so refreshing the existing mapping object
is preferable to rebinding the name
([`fvk/INTENT_SPEC.md` I7](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/INTENT_SPEC.md#L44)).

## 3. How FVK formally captured the gap

FVK started from the issue's framing of the *state*, not just the symptom, and
wrote the object-identity preference into the intent:

> **I7.** *"Because the issue and hint name `LEVEL_TAGS` as the stale module
> state, refreshing the existing mapping object in place is preferred to
> rebinding it: it makes both `base.LEVEL_TAGS` and existing direct references to
> that mapping observe the refresh."*
> — [`fvk/INTENT_SPEC.md` I7](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/INTENT_SPEC.md#L44)

That intent is pinned to a concrete code fact found by auditing what V1 actually
does — not to the reported `level_tag` test:

> **E9:** V1 *"rebounded `LEVEL_TAGS = utils.get_level_tags()` inside the
> receiver"* → *"Rebinding fixes module-global lookup but does not refresh an
> existing mapping reference."*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md` E9](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/PUBLIC_EVIDENCE_LEDGER.md#L15)

The breadth question is then discharged into a dedicated obligation that the
reported test cannot see:

> **PO-6: Mapping Identity Compatibility.** *"Refreshing the existing mapping
> object, rather than rebinding the global name, preserves any already-held
> reference to that mapping while satisfying all public `Message.level_tag`
> obligations."*
> — [`fvk/PROOF_OBLIGATIONS.md` PO-6](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/PROOF_OBLIGATIONS.md#L51)

This is the gap located by reasoning: the issue and its test only ask that
`Message.level_tag` return the right string (covered by
[PO-2](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/PROOF_OBLIGATIONS.md#L15)),
but the formal contract additionally states the refresh must preserve the
`LEVEL_TAGS` object identity — a property no test in the suite checks, and exactly
the one baseline's rebinding violates.

## 4. From formal output to the fix

The audit raised one compatibility finding against V1 (baseline), tied to its
obligation and then to a concrete V2 edit.

- Finding — V1 rebound the mapping instead of updating it in place:

  > **F-1: V1 Rebound the Mapping Instead of Updating It In Place.**
  > *"`base.LEVEL_TAGS` is rebound to the new effective mapping. `Message.level_tag`
  > reads the module global and is fixed. A pre-existing direct reference to the old
  > mapping object remains stale. … Classification: public compatibility edge,
  > resolved in V2."*
  > — [`fvk/FINDINGS.md` F-1](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/FINDINGS.md#L5)

- The core legacy bug is confirmed fixed and kept by V2 (the receiver itself):

  > **F-2: Legacy Behavior Returned Empty String for In-Domain Custom Tags.**
  > *Recommended change: "Keep the `setting_changed` receiver in `storage.base`." …
  > Classification: code bug, resolved by V1 and preserved by V2.*
  > — [`fvk/FINDINGS.md` F-2](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/FINDINGS.md#L41)

- Iteration guidance turned F-1 into the single V2 refinement:

  > *"Revise V1 minimally by changing the receiver from rebinding `LEVEL_TAGS` to
  > refreshing the existing mapping in place. Trace: Finding F-1 … PO-2 requires
  > refresh on `MESSAGE_TAGS`. PO-6 justifies preserving the mapping object's
  > identity."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/ITERATION_GUIDANCE.md#L7)

- The decision trace records the resulting edit and its provenance:

  > *"Replaced `global LEVEL_TAGS; LEVEL_TAGS = utils.get_level_tags()` with an
  > in-place refresh: `level_tags = utils.get_level_tags(); LEVEL_TAGS.clear();
  > LEVEL_TAGS.update(level_tags)`. Trace: Finding F-1, PO-2, and PO-6."*
  > — [`reports/fvk_notes.md`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/reports/fvk_notes.md#L17)

The causal chain:

```
INTENT_SPEC I7 / EVIDENCE E9  ->  PO-6 (refresh must preserve mapping identity)
                              ->  F-1 (V1 rebinds; held reference stays stale)
                              ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The V2 patch
([`solutions/solution_fvk.patch`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/solutions/solution_fvk.patch))
keeps the same receiver but swaps the rebinding for an in-place refresh —
computing the new tags, then `clear()`-ing and `update()`-ing the existing
mapping
([fvk patch, receiver body](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/solutions/solution_fvk.patch#L17)).
The two patches differ only in those three lines (baseline's two-line rebinding
vs FVK's three-line clear/update). The `V1 -> V2` transition was driven entirely
by the formal finding F-1 and obligation PO-6 — **not** by any new test; the run
had no execution environment and added no tests
([`fvk/FINDINGS.md` F-3](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/FINDINGS.md#L75)).

## 5. Verification

**Tier 3 — source-and-artifact reviewed; not executed.** The run forbade running
tests, Python, or K tooling
([`prompts/fvk.md`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/prompts/fvk.md#L27)),
so there is no harness RED/GREEN and no executed behavioral demonstration. What
was inspected, and supports the conclusions above:

- The two patches were diffed against each other and against the issue. Both add
  the identical `setting_changed` receiver in `storage.base`; they differ only in
  the receiver body — baseline rebinds the global, FVK clears and updates the
  existing mapping. Both therefore fix the reported `level_tag` symptom, and FVK
  additionally preserves the mapping object's identity
  ([baseline](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/solutions/solution_baseline.patch#L17),
  [fvk](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/solutions/solution_fvk.patch#L17)).

- The compatibility audit confirms by source inspection that V2 keeps the public
  `Message.level_tag` property signature and return type unchanged, keeps the
  receiver internal, and only changes the *contents* of the existing mapping —
  not its identity
  ([`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L16)).

**Comparison to the human oracle.** The official gold fix scopes the refresh to
the `setting_changed` receiver and resolves the reported `level_tag` symptom, the
same behavior FVK's V2 achieves. FVK re-derived the in-place refresh from the
PO-6 object-identity obligation rather than from the reference solution. (No gold
artifact is attached to this non-curated run, so this is a prose comparison only.)

## 6. Boundaries & honesty

- **Severity: Low.** The trigger breadth is narrow. Baseline's residual cannot
  produce a wrong `Message.level_tag` result — that public observable is fixed by
  rebinding the global. It bites only code that holds a *direct* reference to the
  original `LEVEL_TAGS` mapping object (e.g. `from django.contrib.messages.storage.base
  import LEVEL_TAGS` captured before the override), which then keeps seeing the
  stale contents. The intent itself notes this is a *compatibility strengthening*,
  not a documented public-API commitment, since `LEVEL_TAGS` is an internal module
  constant not advertised for direct import
  ([`fvk/INTENT_SPEC.md` I7](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/INTENT_SPEC.md#L44)).
  That places it at Low per the rubric — a narrow internal-reference compatibility
  edge, not user-visible data corruption.

- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-python-message-tags.k`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/mini-python-message-tags.k),
  [`message-tags-spec.k`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/message-tags-spec.k))
  and the `kompile`/`kast`/`kprove` commands were written but never run; the run
  artifacts state this explicitly
  ([`fvk/PROOF.md`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/PROOF.md#L94),
  [`fvk/FINDINGS.md` F-3](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/FINDINGS.md#L75)).
  The claim is proof-*structured* reasoning — a contract whose obligations (PO-2,
  PO-6) are discharged by construction — not a machine-checked proof.

- **Attribution.** The existing doc's framing ("baseline leaves stale direct
  references to the `LEVEL_TAGS` mapping after settings overrides; FVK refreshes
  in place") is confirmed by the actual patches: the only delta between the two
  arms is the rebinding-vs-clear/update receiver body. The old doc's references to
  "F-2" and "F-1/PO-6" map correctly onto the artifacts — F-2 is the legacy
  empty-string bug the receiver fixes, F-1/PO-6 is the object-identity residual —
  and are linked precisely above. No machine-checked verdict and no executed
  demonstration exist for this instance; the conclusions rest on patch and source
  review.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro | [`prompts/fvk.md`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/prompts/fvk.md#L2), [`fvk/PUBLIC_EVIDENCE_LEDGER.md` E1/E2](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/PUBLIC_EVIDENCE_LEDGER.md#L7) |
| Root cause (stale module constant) | [`reports/baseline_notes.md`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/reports/baseline_notes.md#L5) |
| Baseline patch (rebinding receiver) | [`solutions/solution_baseline.patch`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/solutions/solution_baseline.patch#L17) |
| Baseline reasoning (placement, rejected alternatives) | [`reports/baseline_notes.md`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/reports/baseline_notes.md#L28) |
| FVK patch (in-place refresh) | [`solutions/solution_fvk.patch`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/solutions/solution_fvk.patch#L17) |
| Intent I7 (prefer in-place refresh) | [`fvk/INTENT_SPEC.md` I7](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/INTENT_SPEC.md#L44) |
| Evidence E9 (V1 rebinds the global) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md` E9](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/PUBLIC_EVIDENCE_LEDGER.md#L15) |
| Obligation PO-2 (receiver refresh) | [`fvk/PROOF_OBLIGATIONS.md` PO-2](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/PROOF_OBLIGATIONS.md#L15) |
| Obligation PO-6 (mapping identity) | [`fvk/PROOF_OBLIGATIONS.md` PO-6](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/PROOF_OBLIGATIONS.md#L51) |
| Finding F-1 (rebind vs in-place) | [`fvk/FINDINGS.md` F-1](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/FINDINGS.md#L5) |
| Finding F-2 (legacy empty-string bug) | [`fvk/FINDINGS.md` F-2](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/FINDINGS.md#L41) |
| Iteration guidance (V1→V2 refinement) | [`fvk/ITERATION_GUIDANCE.md`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace (provenance of edit) | [`reports/fvk_notes.md`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/reports/fvk_notes.md#L17) |
| Compatibility audit | [`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L16) |
| Honesty boundary (no execution) | [`fvk/FINDINGS.md` F-3](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/FINDINGS.md#L75) |
| Proof status / kprove not run | [`fvk/PROOF.md`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/PROOF.md#L94) |
| Constructed K core | [`fvk/mini-python-message-tags.k`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/mini-python-message-tags.k), [`fvk/message-tags-spec.k`](../results/verified018-codex-XC-MINI-PRO-AHP-20260616T062203Z/django__django-15127/fvk/message-tags-spec.k) |
