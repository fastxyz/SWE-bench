# FVK Findings

Status: constructed, not machine-checked.

## F-001: Method-created Context ignored `Engine.autoescape`

- Classification: code bug in the V0 implementation; resolved by V1.
- Evidence: `benchmark/PROBLEM.md` reports that an engine created with `autoescape=False` still renders through `Engine.render_to_string()` as autoescaped.
- Concrete input: `Engine(autoescape=False).render_to_string(template_name, {"value": "<tag>"})`.
- Observed before V1: `Context(context)` defaulted to `autoescape=True`, so rendering observed `context.autoescape == True`.
- Expected: the method-created `Context` observes `context.autoescape == False`.
- Related proof obligations: PO-001, PO-003, PO-004.
- V1 status: discharged by `Context(context, autoescape=self.autoescape)`.

## F-002: Existing `Context` objects must not be rewrapped

- Classification: compatibility preservation; no source change needed.
- Evidence: `Engine.render_to_string()` source comment says existing `Context` objects are accepted for backwards compatibility and should not be rewrapped.
- Concrete input: `Engine(autoescape=False).render_to_string(template_name, Context(data, autoescape=True))`.
- Expected: rendering observes the caller's `Context.autoescape == True`, not the engine value.
- Related proof obligations: PO-002, PO-005.
- V1 status: unchanged and discharged because the `isinstance(context, Context)` branch still returns `t.render(context)`.

## F-003: Template-name selection is not the root cause

- Classification: localization finding; no source change needed.
- Evidence: both `template_name` branches assign `t` before the shared context/rendering logic.
- Concrete input: single template name versus list/tuple of names with the same `engine.autoescape` and context kind.
- Expected: autoescape propagation is identical after selection.
- Related proof obligations: PO-003.
- V1 status: unchanged and discharged.

## F-004: Public compatibility audit found no unhandled API change

- Classification: compatibility finding; no source change needed.
- Evidence: V1 does not change `Engine.render_to_string()` signature or return protocol, and `Context.__init__()` already accepts `autoescape`.
- Concrete input: existing public caller using `render_to_string(template_name, context)` continues to call the same signature.
- Expected: same public call shape; only the internal context autoescape default changes on the reported plain-context path.
- Related proof obligations: PO-005.
- V1 status: discharged.

## Proof-Derived Findings From `/verify`

No proof-derived code bug was found beyond F-001. The constructed proof is not machine-checked, so proof confidence is conditioned on later running the emitted `kompile`/`kprove` commands. This is a verification-status caveat, not an additional source-code defect.
