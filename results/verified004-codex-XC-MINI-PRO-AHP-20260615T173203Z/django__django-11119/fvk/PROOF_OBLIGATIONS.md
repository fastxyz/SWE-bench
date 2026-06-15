# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Plain Context Honors Engine Autoescape

- Claim: `renderToString(EA, TN, plain) => rendered(EA)`.
- Evidence: E1, E2, E3, E5, E6.
- Code path: non-`Context` branch in `Engine.render_to_string()`.
- Discharge: V1 constructs `Context(context, autoescape=self.autoescape)`, and `Context.__init__()` stores that value on `context.autoescape`.
- Status: discharged.

## PO-002: Existing Context Is Preserved

- Claim: `renderToString(EA, TN, existing(CA)) => rendered(CA)`.
- Evidence: E4.
- Code path: `if isinstance(context, Context): return t.render(context)`.
- Discharge: V1 did not change this branch.
- Status: discharged.

## PO-003: Template Selection Branches Share the Same Autoescape Contract

- Claim: `TN` ranges over both single-name and many-name template selection cases without changing the autoescape postcondition.
- Evidence: `Engine.render_to_string()` assigns `t` through `select_template()` or `get_template()` before the shared context logic.
- Discharge: V1 changes only the shared non-`Context` context construction; both template-name branches flow through it.
- Status: discharged.

## PO-004: Render Observable Depends on `context.autoescape`

- Claim: using `rendered(Bool)` is an adequate observable for this defect.
- Evidence: template variable rendering and tag/filter paths read `context.autoescape`.
- Discharge: the model keeps the exact boolean axis that distinguishes `autoescape=False` from the legacy always-true constructed context.
- Status: discharged for the issue scope.

## PO-005: Public Compatibility Is Preserved

- Claim: V1 does not introduce a public signature, return-type, callsite, or override incompatibility.
- Evidence: `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Discharge: the only code change is an internal keyword argument to `Context.__init__()`, whose signature already supports `autoescape`.
- Status: discharged.

## PO-006: Adequacy Gate Passes

- Claim: the formal-English claims are no weaker or stronger than the public intent.
- Evidence: `INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`.
- Discharge: all formal claims are marked PASS in `SPEC_AUDIT.md`; no claim relies solely on legacy behavior.
- Status: discharged.
