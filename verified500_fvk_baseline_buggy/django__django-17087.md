# django__django-17087

## Summary

**Severity:** Low — baseline serializes a nested class method to the right dotted
path but can still emit a non-importable migration reference (a `<locals>` path)
for a *local* class-bound method, and lets a class-bound lambda slip past the
existing lambda rejection.

Baseline and FVK both passed the official SWE-bench evaluation for issue #17087,
with **different** patches. Baseline's one-line `__name__ → __qualname__` change
fixes the reported nested-classmethod path but makes the path more *precise*
without making it more *importable*. The FVK patch added the two guards baseline
left out: reject a class-bound method whose qualified name contains a local-scope
marker, and move the lambda rejection ahead of the class-bound branch so a
class-bound lambda cannot bypass it. The defect is narrow (only unsupported
callable shapes); the case matters because FVK found both gaps by **auditing the
whole serializer branch against an importability invariant**, not by running more
tests.

| Arm | local class-bound method / class-bound lambda rejected | Resolved |
|---|---|---|
| baseline | no — may emit `<locals>` path / lambda path | no |
| gold (human oracle) | (no curated gold patch for this run) | — |
| **fvk** | yes — both raise `ValueError` | **yes** |

## 1. The issue and the real defect

**Django issue #17087 — class methods from nested classes cannot be used as
`Field.default`.** Setting a field default to a nested class method such as
`Profile.Capability.default` made the migration writer emit
`appname.models.Capability.default`, dropping the outer `Profile` qualifier, so
the generated migration referenced a path that does not exist
([`prompts/fvk.md`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/prompts/fvk.md#L2)).
(The existing report carried no GitHub URL, so none is asserted here.)

`django/db/migrations/serializer.py`'s `FunctionTypeSerializer.serialize()` has a
branch for callables bound to a class. It built the dotted path from
`klass.__name__` — the **innermost** class name only — so any nesting was lost.
The user-facing observable is a **migration that imports a path that cannot be
resolved**.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/solutions/solution_baseline.patch)
made the minimal change: use the bound class's qualified name.

```python
return "%s.%s.%s" % (module, klass.__qualname__, self.value.__name__), {
    "import %s" % module
}
```

Baseline was not careless — its notes show it *consciously considered* the
local-scope case and chose to leave it out:

> *"I considered adding broader validation for class-bound methods whose qualified
> name contains local-scope markers such as `<locals>`, but rejected it as outside
> the reported issue. The existing branch did not perform that validation, and the
> minimal fix is to preserve nested class qualification without changing error
> behavior for unrelated cases."*
> — [`reports/baseline_notes.md`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/reports/baseline_notes.md#L33)

That reasoning is half right: switching to `__qualname__` is exactly what the
issue needs. But `__qualname__` is *more* than `__name__` — for a class defined
inside a function it is `outer.<locals>.Inner`. So baseline's own change widened
the set of strings that reach the path formatter, and for a local class-bound
method it now emits a path containing `<locals>` — syntactically a more precise
qualname, semantically still un-importable. Baseline closed the reported hole and
opened an adjacent one.

## 3. How FVK formally captured the gap

FVK started from an intent spec, not the symptom. The decisive item is not the
reported path but the *importability* requirement the path must satisfy:

> **I-2:** *"The serializer output for a callable default must be importable by the
> generated migration. When no importable path exists because the callable is local
> to a function scope, the serializer should reject it instead of emitting invalid
> or unresolvable migration code."*
> — [`fvk/INTENT_SPEC.md`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/INTENT_SPEC.md#L12)

The evidence ledger pins that intent to a concrete code fact found by source audit
— the *non*-class-bound branch already rejects local callables, so the class-bound
branch should too:

> **E-3 (implementation):** *"Non-class-bound branch rejects `"<locals>"` in
> function `__qualname__`."* → *"Local-scope callable paths are not valid migration
> references."*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/PUBLIC_EVIDENCE_LEDGER.md#L9)

Which is discharged into a formal obligation specific to the class-bound branch:

> **PO-2: Local Class-Bound Method Is Rejected.** *Precondition: … `"<" in Q`.
> Postcondition: `serialize()` raises `ValueError("Could not find function %s in
> %s.\n" % (N, M))`.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/PROOF_OBLIGATIONS.md#L17)

This is the crux of FVK's value: **the residual defect was located by reasoning,
not observation.** The issue says "produce the right qualified path"; FVK lifts
that into an importability invariant over the whole `serialize()` branch and the
code audit (E-3) shows the class-bound branch is missing the local-scope guard the
sibling branch already enforces.

## 4. From formal output to the fix

The FVK arm's repair is iterative, and the artifacts record the exact steps where
the formalism changed the patch.

- **V1** shipped only baseline's `__qualname__` change. The whole-branch audit
  against I-2 / PO-2 raised a finding:

  > **F-002: V1 could emit `<locals>` for local class-bound methods.** *"after
  > switching to `klass.__qualname__`, the class-bound branch would emit a dotted
  > path containing `<locals>`, which is not an importable migration reference …
  > reject the callable with the same 'could not find function' style used for
  > local non-class-bound functions."*
  > — [`fvk/FINDINGS.md`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/FINDINGS.md#L27)

- A second finding caught the ordering bug — the class-bound branch ran *before*
  the existing lambda check:

  > **F-003: Class-bound lambda callables bypassed the existing lambda rejection.**
  > *"the class-bound branch ran before the existing lambda check and could emit a
  > dotted path ending in `<lambda>` … move the lambda check before the class-bound
  > branch."*
  > — [`fvk/FINDINGS.md`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/FINDINGS.md#L46)

- The iteration guidance turned both findings into decisions D-2 and D-3:

  > *"D-2. Add a local-scope guard for class-bound methods … V1 would otherwise
  > emit `<locals>` in a migration path … D-3. Move the lambda rejection before the
  > class-bound method branch … the existing lambda rule was bypassed by class-bound
  > callables."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/ITERATION_GUIDANCE.md#L13)

- The decision log records the resulting code change and its provenance:

  > *"Decision D-2 added a guard for `"<"` in `klass.__qualname__` … traced to F-002
  > and PO-2 … Decision D-3 moved the lambda check before the class-bound branch …
  > traced to F-003 and PO-4."*
  > — [`reports/fvk_notes.md`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/reports/fvk_notes.md#L11)

The causal chain is fully on the record:

```
INTENT I-2  ->  E-3 (code audit: sibling branch rejects <locals>; class-bound does not)
            ->  F-002 (V1 audit: class-bound branch can emit <locals> path)
            ->  PO-2  (obligation: local class-bound method must raise ValueError)
            ->  F-003/PO-4 (lambda check must precede class-bound branch)
            ->  ITERATION_GUIDANCE D-2/D-3 / fvk_notes  ->  V2 patch
```

The resulting [V2 patch](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/solutions/solution_fvk.patch)
hoists the lambda check and adds the local-marker guard:

```python
def serialize(self):
    if self.value.__name__ == "<lambda>":
        raise ValueError("Cannot serialize function: lambda")
    if getattr(self.value, "__self__", None) and isinstance(self.value.__self__, type):
        klass = self.value.__self__
        module = klass.__module__
        if "<" not in klass.__qualname__:
            return ("%s.%s.%s" % (module, klass.__qualname__, self.value.__name__),
                    {"import %s" % module})
        raise ValueError("Could not find function %s in %s.\n"
                         % (self.value.__name__, module))
```

The `V1 -> V2` transition was driven by `F-002`/`F-003` and `PO-2`/`PO-4`,
**not** by a new failing test — the prompt forbids editing tests and there is no
local-class-bound or class-bound-lambda test in the run (see §5).

## 5. Verification

**Tier 3 — source-and-artifact reviewed; not executed.** This run produced no
harness RED/GREEN reports (census `proof=no`, no curated `_proof` directory) and
no executed demonstration table; the prompt bars running tests, Python, or K
tooling. What was inspected:

- The two patches were diffed: the FVK patch hoists the lambda check, replaces
  `klass.__name__` with `klass.__qualname__` under a `"<" not in klass.__qualname__`
  guard, and adds the `ValueError` reject for the local case
  ([`solution_baseline.patch`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/solutions/solution_baseline.patch),
  [`solution_fvk.patch`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/solutions/solution_fvk.patch)).
- The branch behavior is reasoned out as a four-case split in the proof sketch
  (lambda → reject; importable class-bound → qualname path; local class-bound →
  reject; non-class-bound → unchanged)
  ([`fvk/PROOF.md`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/PROOF.md#L16)).

**Gold comparison.** This run is non-curated, so there is no gold patch file to
diff against. The existing report's claim — that FVK added unsupported-callable
guards baseline omitted — is confirmed against the patches themselves; no claim
about the human oracle's contents is made, since that artifact is absent here.

## 6. Boundaries & honesty

- **Severity: Low.** The trigger breadth is narrow: the residual defect only fires
  on a *local* class-bound method (a class defined inside a function) or a
  *class-bound lambda* used as a field default — uncommon shapes. The value
  demonstrated is detection completeness, not impact magnitude
  ([`fvk/FINDINGS.md` F-002](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/FINDINGS.md#L27)).
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-python-serializer.k`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/mini-python-serializer.k),
  [`django-serializer-spec.k`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/django-serializer-spec.k))
  and the `kompile`/`kast`/`kprove` commands were *written but never run* — the FVK
  artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/PROOF.md#L1)).
  We claim **proof-structured reasoning** (a formal branch case-split with
  obligations discharged by construction), **not a machine-checked proof**.
- **Attribution.** The `V1 -> V2` iteration is documented across `FINDINGS.md`,
  `ITERATION_GUIDANCE.md`, and `fvk_notes.md`. The discrepancy with the existing
  report is only structural (the old doc was a bullet list); the same residual
  defects (local class-bound `<locals>` path, class-bound lambda bypass) and the
  same fix are restated here as a reasoning chain — no claim was reversed.

## Artifact map

| Claim | Source |
|---|---|
| Issue / task statement | [`prompts/fvk.md`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/prompts/fvk.md#L2) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/solutions/solution_baseline.patch) |
| Baseline reasoning (rejected `<locals>` guard) | [`reports/baseline_notes.md`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/reports/baseline_notes.md#L33) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/solutions/solution_fvk.patch) |
| Intent I-2 (importability) | [`fvk/INTENT_SPEC.md#L12`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/INTENT_SPEC.md#L12) |
| Evidence E-3 (sibling branch rejects `<locals>`) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L9`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/PUBLIC_EVIDENCE_LEDGER.md#L9) |
| Obligation PO-2 | [`fvk/PROOF_OBLIGATIONS.md#L17`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/PROOF_OBLIGATIONS.md#L17) |
| Finding F-002 (`<locals>` path) | [`fvk/FINDINGS.md#L27`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/FINDINGS.md#L27) |
| Finding F-003 (lambda bypass) | [`fvk/FINDINGS.md#L46`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/FINDINGS.md#L46) |
| Iteration decisions D-2/D-3 | [`fvk/ITERATION_GUIDANCE.md#L13`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/ITERATION_GUIDANCE.md#L13) |
| Decision trace | [`reports/fvk_notes.md#L11`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/reports/fvk_notes.md#L11) |
| Proof sketch (four-case split) | [`fvk/PROOF.md#L16`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/PROOF.md#L16) |
| Proof status (not machine-checked) | [`fvk/PROOF.md#L1`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/PROOF.md#L1) |
| Constructed K core | [`fvk/mini-python-serializer.k`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/mini-python-serializer.k), [`fvk/django-serializer-spec.k`](../results/verified026-codex-archlinux-20260616T074401Z/django__django-17087/fvk/django-serializer-spec.k) |
