# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Machine-Check Commands

These commands are recorded for a future environment with K installed:

```sh
kompile fvk/mini-call-command.k --backend haskell
kast --backend haskell fvk/call-command-spec.k
kprove fvk/call-command-spec.k
```

Expected machine-check result after the commands are run: `kprove` returns
`#Top` for the stated claims.

## Claims Proved Constructively

C-001. A supplied kwarg from a required mutually exclusive group is included in
the synthetic parser tokens before `parser.parse_args()`.

Linked obligations: PO-001, PO-003. Linked finding: F-001.

C-002. Ordinary required options supplied in kwargs remain included in synthetic
parser tokens.

Linked obligations: PO-001, PO-002.

C-003. Missing required-group values and conflicting required-group values are
not manually accepted by Django; they remain delegated to argparse.

Linked obligations: PO-004. Linked finding: F-002.

C-004. Synthetic tokens do not replace final kwarg values passed to command
execution.

Linked obligation: PO-005.

C-005. The patch does not change public API shape or unknown-option rejection.

Linked obligations: PO-006, PO-007.

## Constructed Proof Sketch

1. `call_command()` constructs `parser` and `arg_options`. By PO-001,
   all later required-option decisions are made over normalized dest names.

2. `parser_actions = list(get_actions(parser))` contains ordinary parser
   actions, including actions reachable through the existing subparser traversal.

3. For ordinary required actions, V1 builds `required_options` from actions whose
   `required` flag is true and whose dest is supplied. The final loop appends
   `get_option_args(opt)` for each such action. This is C-002.

4. Required mutually exclusive group actions are not individually marked
   required by argparse, so step 3 alone cannot satisfy the reported intent.
   V1 separately traverses `parser._mutually_exclusive_groups`, selects only
   groups where `group.required` is true, and yields each group action whose
   dest is supplied in `arg_options`. Extending `required_options` with those
   yielded actions puts them through the same token-appending loop. This is
   C-001.

5. If no group action dest is supplied, the group traversal yields nothing for
   that group. Therefore no synthetic token is fabricated and `parse_args()`
   can still raise the required-group error. If two group action dests are
   supplied, both actions are yielded and both tokens are appended; V1 does not
   collapse the group to an arbitrary winner. Therefore `parse_args()` can still
   reject the mutual-exclusion conflict. This is C-003.

6. `seen_options` removes duplicate action objects, not duplicate token strings,
   so repeated values for multi-value actions are not accidentally dropped.

7. `parser.parse_args(args=parse_args)` is called after synthetic tokens are
   added. The proof treats argparse as the delegated validator and does not
   attempt to prove argparse internals.

8. `defaults = dict(defaults._get_kwargs(), **arg_options)` preserves the
   existing Django design: parser output supplies defaults and validation, while
   explicit kwargs override final values. This is C-004.

9. Unknown option rejection and the public call signature are unchanged. This is
   C-005.

## Test Guidance

Do not delete tests based on this constructed proof. If machine-checked later,
unit tests covering only the in-domain cases below would be candidates for
redundancy, but removal must remain conditional on `kprove` returning `#Top`:

- required mutually exclusive group satisfied by `shop_id=1`;
- required mutually exclusive group satisfied by `shop_name='name'`;
- ordinary required option supplied as kwarg.

Keep or add tests for behavior outside the formal slice:

- no group kwarg still raises the required-group error;
- both mutually exclusive kwargs still raise an argparse conflict;
- unknown kwargs still raise `TypeError`;
- integration tests for actual command execution.

## Residual Risk

The proof is partial correctness for the synthetic parsing slice. It does not
prove termination, full argparse behavior, exact error messages, or every exotic
argparse action class. Those are recorded as F-004 rather than source defects in
the public issue scope.
