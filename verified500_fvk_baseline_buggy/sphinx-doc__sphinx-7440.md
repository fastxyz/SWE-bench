# sphinx-doc__sphinx-7440

## Summary

**Severity:** Low — baseline changes the public pending-reference target shape
for `:term:` roles, which only affects intersphinx/extension consumers of
`pending_xref['reftarget']`, not the reported user-visible warning. The main
glossary bug is fixed by both arms; the residual gap is a narrow compatibility
regression in an intermediate representation, so the practical blast radius is
small.

Both arms passed the official SWE-bench evaluation for this issue with
**different** patches. The FVK patch keeps the public `reftarget` lowercased (as
historical Sphinx did) by adding a `TermXRefRole` that stashes the original
spelling on the node, where baseline simply stops lowercasing and lets the
original-case spelling leak into the public target. The case is interesting for
**how FVK located the regression** — by formalizing the role's target shape as a
compatibility obligation and auditing it — not for impact magnitude.

| Arm | [`tests/test_domain_std.py::test_glossary`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/eval/baseline.report.json) | Public `reftarget` preserved |
|---|---|---|
| baseline | [resolved](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/eval/baseline.report.json) | no — leaks original case |
| **fvk** | [resolved](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/eval/fvk.report.json) | **yes — kept lowercased** |

## 1. The issue and the real defect

The reported defect: a glossary that defines both `MySQL` and `mysql` raises
`duplicate term description of mysql` and treats them as one entry, even though
they are intended to be distinct terms. The issue text asks plainly
*"`MySQL != mysql` term right?"*, captured in the evidence ledger as
[E-001/E-002](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/PUBLIC_EVIDENCE_LEDGER.md#L3).

The root cause is in `sphinx/domains/std.py`: `make_glossary_term()` registered
the term under `termtext.lower()`, so `MySQL` and `mysql` collapsed to the same
`('term', 'mysql')` key in the standard-domain object map and tripped the
duplicate check
([`reports/baseline_notes.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/reports/baseline_notes.md#L4)).
A secondary coupling: the `:term:` role itself lowercased its reference target
(`XRefRole(lowercase=True, ...)`), so even after registration became
case-sensitive, the original spelling of a `:term:` reference was lost before
the domain could resolve it.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/solutions/solution_baseline.patch)
made the registration key exact (`note_object('term', termtext, ...)`) and added
a `_resolve_term()` helper with an exact-first, unambiguous-fallback lookup. That
part is correct and matches what the FVK arm also keeps. The reasoning is sound
and documented
([`reports/baseline_notes.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/reports/baseline_notes.md#L23)):
to let an exact-case reference resolve, it *stopped lowercasing* the `:term:`
target by dropping `lowercase=True` from the role:

```python
# baseline
'term':    XRefRole(innernodeclass=nodes.inline, warn_dangling=True),
```
([`solution_baseline.patch`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/solutions/solution_baseline.patch#L20))

This fixes the warning and exact-case resolution. But it also changes the
**public** `pending_xref['reftarget']`: a `:term:` MySQL reference now carries
`reftarget == 'MySQL'` instead of the historical `'mysql'`. That target is
consumed directly downstream — intersphinx's `missing_reference()` looks it up
against external inventories that hold *lowercased* term names. Baseline left
that compatibility obligation unmet: it fixed the domain keys but mutated a
public intermediate representation one step beyond what the issue required.

## 3. How FVK formally captured the gap

FVK reasoned from intent, not from the symptom. The intent spec separates the
registration fix from a compatibility constraint on the role's *output target
shape*:

> **I-004:** *Historical lowercased term-reference target shape should be
> preserved where possible … the public pending-xref `reftarget` for `:term:`
> should remain lowercased for compatibility, while local resolution may carry
> extra metadata to distinguish exact spellings.*
> — [`fvk/INTENT_SPEC.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/INTENT_SPEC.md#L34)

That intent is pinned to a concrete code-and-compatibility fact found by source
audit, not by a test:

> **E-004:** *base standard-domain `roles` used `XRefRole(lowercase=True, …)` for
> `term`; `intersphinx.missing_reference()` uses `node['reftarget']` directly for
> inventory lookup … preserve the lowercased public `reftarget` shape unless
> public intent requires changing it. … V1 violated this compatibility
> condition; V2 fixes it with `TermXRefRole`.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/PUBLIC_EVIDENCE_LEDGER.md#L27)

Which is discharged into a pair of obligations that together state the desired
shape — the public target stays lowercased while the original spelling rides
along on the node for local resolution:

> **PO-004 — Term Role Preserves Lowercased Reftarget.** *`:term:` pending
> references keep the historical lowercased `reftarget` shape … `TermXRefRole.process_link()`
> … stores the original target in `std:term-original`, and returns `target.lower()`
> as the public target.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/PROOF_OBLIGATIONS.md#L42)

> **PO-005 — Local Term Resolution Prefers Exact Original Spelling.** *`_resolve_obj_xref()`
> calls `_resolve_term()` with `node.get('std:term-original', target)`, so local
> `std:term` resolution sees the original spelling.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/PROOF_OBLIGATIONS.md#L55)

The crux: FVK treats the lowercased `reftarget` as a *public contract*, separate
from the internal need for the exact spelling. Baseline conflated the two and
satisfied internal resolution by sacrificing the public shape; FVK's obligations
require satisfying both at once.

## 4. From formal output to the fix

The audit recorded the exact step where the formalism changed the patch. The V1
fix (baseline's approach) was found to break the compatibility obligation:

> **F-002: V1 Changed Public Pending-XRef Target Shape.** *removing `lowercase=True`
> made `pending_xref['reftarget'] == 'MySQL'` … keep the previous lowercased
> public `reftarget == 'mysql'`, because intersphinx inventory lookup uses
> `reftarget` directly … Classification: compatibility regression introduced by
> V1. Resolution: fixed in V2 by adding `TermXRefRole`.*
> — [`fvk/FINDINGS.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/FINDINGS.md#L29)

The iteration guidance turned the finding into the concrete role/resolver
revision:

> *`TermXRefRole` preserves the historical lowercased `reftarget`. `TermXRefRole`
> stores the normalized original target in `std:term-original`. `_resolve_obj_xref()`
> uses `std:term-original` for local exact term lookup.*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/ITERATION_GUIDANCE.md#L13)

And the decision trace records it against F-002/PO-004/PO-005:

> **Repair V1's `:term:` role compatibility regression.** *add `TermXRefRole`. It
> stores the normalized original target in `pending_xref['std:term-original']` but
> returns `target.lower()` as the public `reftarget`.*
> — [`reports/fvk_notes.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/reports/fvk_notes.md#L22)

The resulting [FVK patch](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/solutions/solution_fvk.patch)
adds the role class and wires it in, instead of dropping `lowercase` outright:

```python
class TermXRefRole(XRefRole):
    def process_link(self, env, refnode, has_explicit_title, title, target):
        title, target = super().process_link(env, refnode, has_explicit_title, title, target)
        refnode['std:term-original'] = target
        return title, target.lower()
```
([`solution_fvk.patch`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/solutions/solution_fvk.patch#L18)),
wired as `'term': TermXRefRole(...)`
([line 35](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/solutions/solution_fvk.patch#L35)),
and resolved via `node.get('std:term-original', target)`
([line 49](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/solutions/solution_fvk.patch#L49)).

The causal chain:

```
INTENT_SPEC I-004  ->  E-004 (audit: role was lowercase=True; intersphinx reads reftarget)
                   ->  F-002 (V1 audit: dropping lowercase leaks 'MySQL' into public target)
                   ->  PO-004 / PO-005 (keep reftarget lowercased; carry std:term-original)
                   ->  ITERATION_GUIDANCE / fvk_notes  ->  TermXRefRole patch
```

The V1→V2 transition was driven by the **formal compatibility finding F-002**,
not by a new failing test — the run forbade running or adding tests
([prompt, no-exec section](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/prompts/fvk.md#L26)).

## 5. Verification

This case is **non-curated** (analysis=no): there is no curated harness proof of
the residual gap, no gold patch in the run, and no executed demonstration in the
prior doc. Verification is **source-and-artifact review, not executed**.

What was inspected:

- **Official evaluation** — both arms resolve the upstream `test_glossary`
  ([baseline](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/eval/baseline.report.json),
  [fvk](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/eval/fvk.report.json)),
  so the reported warning is fixed in both. That test does **not** assert the
  `reftarget` shape, which is why the residual gap survives a passing run.
- **Patch diff** — baseline sets the `:term:` role to
  `XRefRole(innernodeclass=..., warn_dangling=True)` with no lowercasing
  ([`solution_baseline.patch`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/solutions/solution_baseline.patch#L20)),
  whereas fvk adds `TermXRefRole` returning `target.lower()`
  ([`solution_fvk.patch`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/solutions/solution_fvk.patch#L18)).
  The behavioral difference (`reftarget == 'MySQL'` vs `'mysql'`) follows by
  reading these two hunks; it was not run.
- **Constructed proof sketch** for PO-004/PO-005 in
  [`fvk/PROOF.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/PROOF.md#L41),
  reasoning that `process_link` keeps the public target lowercased while local
  resolution reads `std:term-original`.

No harness report isolates the `reftarget` regression, and no `kprove` was run;
the gap is established by reading the patches and artifacts, not by a red/green
oracle.

## 6. Boundaries & honesty

- **Severity: Low.** The trigger is narrow: only consumers that read the
  *public* `pending_xref['reftarget']` for a `:term:` role — intersphinx
  inventory lookup and third-party extensions — see baseline's changed shape. The
  reported user-visible warning is fixed in both arms, and an internal Sphinx
  build resolves terms through the domain regardless. Low reflects this small
  trigger breadth, per the rubric; the value here is FVK's **detection of a
  compatibility regression in an intermediate representation**, not impact size.
- **Proof status: constructed, not machine-checked.** The K artifacts and the
  `kompile`/`kast`/`kprove` commands were written but never run — the artifacts
  state this explicitly
  ([`fvk/PROOF.md`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/PROOF.md#L3),
  [finding F-004](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/FINDINGS.md#L65)).
  We claim **proof-structured reasoning** (a spec with obligations discharged by
  construction), **not** a machine-checked proof.
- **Attribution caveats.** The baseline-vs-fvk behavioral difference is read off
  the two patch hunks; it was not executed or harness-confirmed, because no test
  in the suite asserts the `reftarget` shape. The compatibility claim about
  intersphinx rests on FVK's own source audit (E-004), not on an independent
  reproduction in this run. The fvk arm uses a **split-file** artifact schema
  (intent in `INTENT_SPEC.md`, evidence in `PUBLIC_EVIDENCE_LEDGER.md`,
  obligations in `PROOF_OBLIGATIONS.md`), so the §3 chain spans three files
  rather than one `SPEC.md`.

## Artifact map

| Claim | Source |
|---|---|
| Issue text (`MySQL != mysql`), duplicate warning | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L3`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/PUBLIC_EVIDENCE_LEDGER.md#L3) |
| Root cause (lowercased registration key) | [`reports/baseline_notes.md#L4`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/reports/baseline_notes.md#L4) |
| Baseline stops lowercasing the role | [`reports/baseline_notes.md#L23`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/reports/baseline_notes.md#L23), [`solution_baseline.patch#L20`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/solutions/solution_baseline.patch#L20) |
| Intent I-004 (preserve lowercased reftarget) | [`fvk/INTENT_SPEC.md#L34`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/INTENT_SPEC.md#L34) |
| Evidence E-004 (intersphinx reads reftarget) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L27`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/PUBLIC_EVIDENCE_LEDGER.md#L27) |
| Obligation PO-004 / PO-005 | [`fvk/PROOF_OBLIGATIONS.md#L42`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/PROOF_OBLIGATIONS.md#L42), [`#L55`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/PROOF_OBLIGATIONS.md#L55) |
| Finding F-002 (V1 regression) | [`fvk/FINDINGS.md#L29`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/FINDINGS.md#L29) |
| Iteration guidance (TermXRefRole) | [`fvk/ITERATION_GUIDANCE.md#L13`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/ITERATION_GUIDANCE.md#L13) |
| Decision trace (add TermXRefRole) | [`reports/fvk_notes.md#L22`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/reports/fvk_notes.md#L22) |
| FVK patch hunk (TermXRefRole / std:term-original) | [`solution_fvk.patch#L18`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/solutions/solution_fvk.patch#L18), [`#L35`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/solutions/solution_fvk.patch#L35), [`#L49`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/solutions/solution_fvk.patch#L49) |
| No-test / no-exec constraint | [`prompts/fvk.md#L26`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/prompts/fvk.md#L26) |
| Both arms resolved (official eval) | [`eval/baseline.report.json`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/eval/baseline.report.json), [`eval/fvk.report.json`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/eval/fvk.report.json) |
| Constructed proof sketch (PO-004) | [`fvk/PROOF.md#L41`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/PROOF.md#L41) |
| Proof not machine-checked | [`fvk/PROOF.md#L3`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/PROOF.md#L3), [`fvk/FINDINGS.md#L65`](../results/verified039-codex-wsl-ubuntu-260615221107/sphinx-doc__sphinx-7440/fvk/FINDINGS.md#L65) |
