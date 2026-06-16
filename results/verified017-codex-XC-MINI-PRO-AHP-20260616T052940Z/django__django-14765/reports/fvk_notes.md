# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a source-code problem that
justifies a V2 edit.

## Trace to Findings and Proof Obligations

- Kept the V1 assertion branch because `F1` confirms the pre-fix bug and `PO3`
  states the required non-set, non-`None` behavior: assertion instead of
  conversion. V1 satisfies this at `repo/django/db/migrations/state.py:97-98`.
- Kept the `real_apps is None` branch because `F2` and `PO1` require the
  sentinel `None` path to continue creating an empty set. V1 satisfies this at
  `repo/django/db/migrations/state.py:94-95`.
- Kept the `is None` condition instead of reverting to truthiness because `F3`
  and `PO2` require empty sets to count as provided non-`None` set values.
- Made no compatibility workaround for list or tuple inputs because `F4`, `PO3`,
  and `PO5` classify that behavior change as intentional under the issue text,
  while source call sites remain set-valued or `None`.
- Made no unrelated constructor edits because `PO4` requires preservation of
  `models`, `is_delayed`, and `relations` behavior on successful construction.
- Did not run or claim machine verification because `F5` and `PO6` record the
  environment and task restriction. The emitted K commands remain instructions
  for a later environment.

## Artifact Decisions

The task required five files under `fvk/`, and the FVK documentation also
requires an adequacy ledger and formal `.k` core. I therefore wrote the required
files:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also wrote the FVK adequacy and formal-core files:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python.k`
- `fvk/projectstate-spec.k`

## Assumptions

- Normal Python assertion semantics are in scope. Python `-O` disables asserts,
  but the issue explicitly asks for an assertion, so optimized assertion
  removal is outside this fix's contract.
- The formal model intentionally abstracts to the `real_apps` input shape
  (`None`, empty set, non-empty set, non-set) because that is the property axis
  changed by the issue. It still distinguishes passing and failing instances on
  that axis.
- Tests remain fixed and hidden for this benchmark. No test file was modified
  and no test removal is recommended without a future machine-checked proof.
