# Intent Spec

Status: intent-only, derived from public evidence before treating V1 behavior as
the expected behavior.

## Obligations

I-001. A kwarg for an argument in a required mutually exclusive group must count
as satisfying that group for `call_command()`.

I-002. The working command-line spelling, for example `--shop-id=1`, is the
behavioral reference for parser presence validation.

I-003. Existing ordinary required-option kwargs must continue to work.

I-004. Argparse remains the authority for missing required groups and
mutual-exclusion conflicts.

I-005. The public API shape of `call_command()` must not change.

## Out Of Scope

This intent does not require Django to reimplement all argparse validation.
`call_command()` must make relevant kwargs visible to argparse, then preserve
argparse as the validator.
