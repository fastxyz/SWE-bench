# Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and the constructed proof obligations.

## F-001: Choices enum classes were called before member lookup

- Classification: code bug, fixed by V1.
- Input: a template path equivalent to `YearInSchool.FRESHMAN` with
  `YearInSchool` bound to a `models.TextChoices` class.
- Observed before V1: the template resolver sees the intermediate class as
  callable and attempts a zero-argument call; the class constructor requires a
  value, so the member lookup cannot complete.
- Expected: the resolver must preserve the enum class and then resolve
  `FRESHMAN`.
- Evidence: E-001 through E-006.
- Proof obligations: PO-001, PO-002, PO-003.
- Status: resolved by V1. No additional source edit is required.

## F-002: The template resolver already has the required hook

- Classification: no code bug in the resolver.
- Input: any callable value with `do_not_call_in_templates == True`.
- Observed in source: `Variable._resolve_lookup()` checks the marker before
  `alters_data` or a zero-argument call, and leaves the value unchanged.
- Expected: use this existing hook rather than changing callable resolution for
  all callables.
- Evidence: E-005, E-006.
- Proof obligations: PO-002, PO-005.
- Status: confirmed. V1 correctly changes the choices enum class, not the
  template resolver.

## F-003: The marker must not become an enum member

- Classification: implementation hazard avoided by V1.
- Input: adding `do_not_call_in_templates = True` directly in the body of an
  `Enum` subclass.
- Observed risk: plain assignments in an enum class body can be interpreted as
  enum members before `EnumMeta` creates the class.
- Expected: the marker must be a class attribute visible to templates without
  changing the enum member set.
- Evidence: E-007, E-008.
- Proof obligations: PO-004.
- Status: avoided by V1 because the assignment is made after
  `EnumMeta.__new__()` returns the class.

## Proof-derived findings from `/verify`

No additional source defect was surfaced by the constructed proof. The only
remaining proof limitation is procedural: the K artifacts were constructed but
not machine-checked, as required by the task constraints.
