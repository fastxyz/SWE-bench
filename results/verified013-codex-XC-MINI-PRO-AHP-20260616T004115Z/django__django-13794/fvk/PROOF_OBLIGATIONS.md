# Proof Obligations

Status: constructed for FVK audit; not machine-checked.

## PO-1: Adequacy and Evidence

- Obligation: every formal claim must trace to public intent rather than V1
  behavior alone.
- Evidence: E-1 through E-8 in `PUBLIC_EVIDENCE_LEDGER.md`.
- Status: discharged by `INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, and
  `SPEC_AUDIT.md`.

## PO-2: Text-Promise Resolution

- Obligation: if an operand is a Django `Promise` with `_delegate_text`, the
  filter must replace it with `str(operand)` before branch selection.
- Source: `defaultfilters.py:678-681`.
- Intent: E-1, E-2, E-6, E-7.
- Status: discharged. This removes the reported `str + __proxy__` failure.

## PO-3: Integer Coercion Has Priority

- Obligation: after PO-2 resolution, if both operands are accepted by `int()`,
  return the integer sum.
- Source: `defaultfilters.py:682-683`.
- Intent: E-3, E-5.
- K claim: `ADD-INT`; specific lazy case `ADD-LAZY-RIGHT-INT`.
- Status: discharged by straight-line branch order.

## PO-4: Native Addition Fallback

- Obligation: after PO-2 resolution, if integer coercion fails but native
  Python addition succeeds, return that addition result.
- Source: `defaultfilters.py:684-686`.
- Intent: E-1, E-4.
- K claim: `ADD-PLUS`; specific lazy cases `ADD-LAZY-RIGHT-PLUS` and
  `ADD-LAZY-LEFT-PLUS`.
- Status: discharged. The reported lazy text case reduces to normal
  string-plus-string before this branch.

## PO-5: Empty-String Failure Fallback

- Obligation: after PO-2 resolution, if integer coercion and native addition
  both fail, return `""`.
- Source: `defaultfilters.py:687-688`.
- Intent: E-4.
- K claim: `ADD-EMPTY`.
- Status: discharged.

## PO-6: Frame Condition for Existing Behavior

- Obligation: V1 must not change non-lazy operand behavior or non-text lazy
  behavior beyond the issue-required text-promise resolution.
- Source: `defaultfilters.py:678-681` only rewrites text promises; the original
  `int()` / `+` / `""` branches remain intact.
- Intent: E-4, E-8.
- Status: discharged.

## PO-7: Public Compatibility

- Obligation: no public API signature, template registration, callsite, or
  override compatibility regression.
- Evidence: `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Status: discharged.

## PO-8: Honesty Gate

- Obligation: do not claim machine verification or test results.
- Evidence: task constraints and FVK MVP status.
- Status: discharged by labeling all FVK proof artifacts "constructed, not
  machine-checked" and by not running tests, Python, or K tooling.

