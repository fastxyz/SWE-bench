# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and proof obligations only.

## F-001: Required mutually exclusive group kwargs were invisible to argparse

Classification: code bug, closed by V1.

Input: a command whose parser contains
`parser.add_mutually_exclusive_group(required=True)` with options
`--shop-id`/`dest='shop_id'` and `--shop`/`dest='shop_name'`, called as
`call_command('my_command', shop_id=1)`.

Observed before V1: `CommandError: Error: one of the arguments --shop-id --shop
is required`.

Expected: argparse should see `--shop-id=1` presence during the validation pass,
then Django should execute the command with `shop_id=1`.

Evidence: `benchmark/PROBLEM.md`, E-001, E-002.

Resolution: V1 adds required mutually exclusive group actions whose dest appears
in normalized kwargs to the same synthetic parse path used by ordinary required
options. Covered by PO-003.

## F-002: Missing and conflicting group kwargs must still be parser errors

Classification: frame condition, confirmed by V1.

Input A: same parser, but no kwarg from the required group.

Expected A: no synthetic group option is fabricated; argparse can still raise
the required-group error.

Input B: same parser, with both `shop_id=1` and `shop_name='x'`.

Expected B: both supplied group options are represented in the synthetic parse
list, so argparse can reject the mutual-exclusion conflict.

Evidence: I-004, PO-004.

Resolution: V1 filters group actions by supplied dest and does not short-circuit
after the first match. This preserves argparse as the validator.

## F-003: Required-option alias lookup should use normalized kwargs

Classification: compatibility improvement, confirmed by V1.

Input: a required option whose public option-string key maps to a different
dest, supplied through the option-string-derived kwarg name.

Observed in pre-V1 source: required-option synthesis checked `opt.dest in
options`, even though the value lookup used `arg_options[opt.dest]`.

Expected: the required-option synthesis should use the normalized kwarg map that
the rest of `call_command()` already uses.

Evidence: source inspection, E-003, E-004.

Resolution: V1 checks `opt.dest in arg_options`. Covered by PO-001 and PO-002.

## F-004: Proof scope is narrower than full argparse

Classification: proof capability boundary, not a source bug for this issue.

The formal model covers the `call_command()` obligation to expose required
kwargs and required mutually exclusive group kwargs to argparse. It does not
prove the full Python `argparse` implementation, all exotic action classes, or
the exact text of parser errors.

Evidence: SPEC scope and PROOF_OBLIGATIONS.md.

Decision: no source change. The public issue uses ordinary optional actions
with scalar values, and V1 delegates final validation to argparse rather than
reimplementing it.
