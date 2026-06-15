# FVK Specification

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited unit is `django.core.management.call_command()` in
`repo/django/core/management/__init__.py`, limited to the synthetic argument
construction performed before `parser.parse_args(args=parse_args)`.

The specification treats Django's `CommandParser` and Python `argparse` as the
delegated validator once `call_command()` supplies the correct synthetic tokens.
The proof obligations are partial-correctness obligations over this slice:
if the parser and options are in the stated domain, the synthetic parse token
list has the required presence information and argparse then validates required
groups, conflicts, and required options.

## Intent Spec

I-001. A kwarg for an argument in a required mutually exclusive group must count
as satisfying that group for `call_command()`.

Evidence: `benchmark/PROBLEM.md` says `call_command('my_command', shop_id=1)`
raises `Error: one of the arguments --shop-id --shop is required`, while
`shop_id` is part of `parser.add_mutually_exclusive_group(required=True)`.

I-002. Command-line spelling already works and is the behavioral reference for
presence validation.

Evidence: `benchmark/PROBLEM.md` says calling the command with `'--shop-id=1'`
works.

I-003. Existing required-option kwargs must keep working.

Evidence: the source comment in `call_command()` says required arguments passed
via `**options` must be passed to `parse_args()`, and public in-repo tests cover
required kwargs in `tests/user_commands/tests.py`.

I-004. Argparse should remain the authority for missing required groups and
mutual-exclusion conflicts.

Evidence: the issue objects only to a supplied kwarg being invisible to argparse,
not to argparse's validation policy.

I-005. The public API shape of `call_command()` must not change.

Evidence: the task asks for a minimal source fix. The issue is behavioral, not
an API redesign.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt | "`call_command('my_command', shop_id=1)`" fails even though `shop_id` is in a required mutually exclusive group | include supplied required-group kwargs in synthetic parse args | encoded in PO-003 and `call-command-spec.k` |
| E-002 | prompt | "`--shop-id=1`" works | synthetic kwarg path should make argparse observe equivalent option presence | encoded in PO-003 |
| E-003 | source comment | required `**options` must be passed to `parse_args()` | preserve required plain option behavior | encoded in PO-002 |
| E-004 | implementation | `defaults = dict(defaults._get_kwargs(), **arg_options)` | final command options still come from kwargs after parser validation | encoded in PO-005 |
| E-005 | implementation | unknown option check uses original option keys and parser action dests | preserve `TypeError` for truly unknown kwargs | encoded in PO-006 |

## Formal Core

Formal artifacts:

- `fvk/mini-call-command.k`: a small K-style semantics for the audited synthetic
  argument phase.
- `fvk/call-command-spec.k`: reachability claims for the reported required
  mutually exclusive group case, ordinary required options, and the no-kwarg
  required-group frame condition.

The `.k` model abstracts actual kwarg values as `VALUE`. This is intentional:
the proof obligation is that argparse sees the supplied option's presence during
required-group validation. Final Python values are covered separately by PO-005,
and full argparse type conversion is outside this mini semantics.

Exact commands to run later, not executed here:

```sh
kompile fvk/mini-call-command.k --backend haskell
kast --backend haskell fvk/call-command-spec.k
kprove fvk/call-command-spec.k
```

Expected result after a real machine check: all claims discharge to `#Top`.

## Formal Spec In English

FSE-001. If a required mutually exclusive group contains `shop_id` and
`shop_name`, and the caller supplies `shop_id` in kwargs, synthetic parser
tokens include the corresponding option before `parse_args()`.

FSE-002. If an ordinary required option is supplied in kwargs, synthetic parser
tokens still include that option before `parse_args()`.

FSE-003. If no kwarg from a required mutually exclusive group is supplied,
`call_command()` does not fabricate a group token. Argparse remains responsible
for raising the required-group error.

FSE-004. If more than one kwarg from the same mutually exclusive group is
supplied, V1 passes all supplied group options through synthetic parsing, so
argparse remains responsible for rejecting the conflict.

## Adequacy Audit

| Formal item | Intent coverage | Result |
| --- | --- | --- |
| FSE-001 | Covers I-001 and I-002 | pass |
| FSE-002 | Covers I-003 | pass |
| FSE-003 | Covers I-004 for missing group values | pass |
| FSE-004 | Covers I-004 for conflicting group values | pass |
| Public API unchanged | Covers I-005 | pass |

No formal claim depends on hidden tests, upstream patches, benchmark results, or
candidate behavior alone.

## Public Compatibility Audit

Changed symbol: `django.core.management.call_command()`.

Compatibility result: pass. V1 does not change the function signature, return
shape, command loading behavior, `execute()` call shape, or public test files.
It only changes which parser action tokens are added to `parse_args()` before
existing validation.
