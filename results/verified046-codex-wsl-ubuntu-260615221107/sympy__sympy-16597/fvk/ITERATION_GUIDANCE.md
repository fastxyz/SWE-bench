# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

Keep V1 unchanged.

The FVK audit confirms that the single old-assumption rule
`rational -> finite` discharges the issue examples and the related rational
family without duplicating leaf rules.

## Suggested Follow-up Tests

Do not edit tests in this benchmark task. For a normal development pass, add or
confirm tests equivalent to:

- `Symbol('m', even=True).is_finite is True`
- `Symbol('i', integer=True).is_finite is True`
- `Symbol('r', rational=True).is_finite is True`
- `Symbol('x').is_finite is None`
- `Symbol('x', real=True).is_finite` remains the pre-existing old-assumption
  behavior

## Future Work Outside This Patch

The newer `ask(Q.*)` facts and generated `ask_generated.py` tables contain a
related but separate consistency question. If that API is addressed later, do it
as a dedicated patch:

1. Decide whether `Q.rational -> Q.finite` or `Q.real -> Q.finite` is the intended
   public contract for that API.
2. Update `get_known_facts`.
3. Regenerate `ask_generated.py` with `bin/ask_update.py`.
4. Audit public finite/sign tests that currently combine sign predicates with
   `~Q.finite`.

This was not done here because the reported issue and hint target old
`.is_*` assumptions and `_assume_rules`.
