# FVK Findings

Status: constructed, not machine-checked.

## F1 - Legacy default-manager validation rejects base-visible rows

- Classification: code bug in V0; fixed by V1.
- Evidence: E1, E2, E3, E4.
- Concrete input: related value `123` where `baseExists=true`,
  `defaultExists=false`, and `limitAllows=true`.
- Observed before V1: validation queried `_default_manager`, so the row looked
  missing and an invalid "does not exist" error was raised.
- Expected: validation should query `_base_manager`, see the row, and accept it.
- V1 status: resolved by changing `remote_field.model._default_manager` to
  `remote_field.model._base_manager` in `ForeignKey.validate()`.

## F2 - Limit choices remain an explicit rejection path

- Classification: intended frame condition, not a code bug.
- Evidence: E6 and the problem's manager-only scope.
- Concrete input: related value `123` where `baseExists=true`,
  `defaultExists=false`, and `limitAllows=false`.
- Expected: validation may reject because explicit relation limits exclude the
  row.
- V1 status: preserved because the patch leaves
  `qs = qs.complex_filter(self.get_limit_choices_to())` unchanged.

## F3 - Compatibility audit found no public API break

- Classification: no open blocker.
- Evidence: `PUBLIC_COMPATIBILITY_AUDIT.md`, PO5.
- Observed V1: method signature, routing call, target-field filter,
  `limit_choices_to`, return behavior, and exception shape are unchanged.
- Expected: only the manager used for the existence query changes.
- V1 status: no source edit beyond V1 is justified.

## Proof-derived findings from `/verify`

The constructed proof obligations close over the abstract manager-selection
model. No proof-derived code bug was found. The residual risk is proof-tooling
honesty: the K files and claims were written but not run through `kompile` or
`kprove`, per task restrictions.
