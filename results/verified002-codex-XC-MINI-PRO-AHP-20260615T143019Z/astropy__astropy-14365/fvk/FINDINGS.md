# FVK Findings

Status: findings from `/formalize` and `/verify`; proof constructed, not
machine-checked.

## F-001: Resolved code bug - lowercase supported QDP command rejected

- Classification: code bug in V0, resolved by V1.
- Evidence: E1 and E2.
- Input: `read serr 1 2`
- Observed before V1: `_line_type()` did not match the command regex and raised
  `ValueError: Unrecognized QDP line: read serr 1 2`.
- Expected: line classifies as `command`, allowing the file to read into a
  `Table` with symmetric errors.
- Proof obligations: PO-001 and PO-002.
- V1 status: satisfied by the scoped inline case-insensitive regex group
  `(?i:READ [TS]ERR)`.

## F-002: No additional source change required for err-spec propagation

- Classification: confirmation of downstream path.
- Evidence: E4.
- Input: accepted command tokens such as `read serr 1 2` or `Read Terr 3`.
- Observed in V1 by source inspection: `_get_tables_from_qdp_file` splits the
  command line and stores `command[1].lower()` as the err-spec key.
- Expected: canonical keys `serr` and `terr` are passed to
  `_interpret_err_lines`.
- Proof obligation: PO-003.
- V1 status: satisfied without further source edits.

## F-003: Broader QDP command vocabulary remains outside the proven contract

- Classification: underspecified intent, not a V1 blocker.
- Evidence: E6.
- Input family: QDP directives other than the reader's supported `READ SERR`
  and `READ TERR` error-column commands.
- Observed: this reader's documented command handling centers on error-column
  directives; the issue's concrete expected behavior is `read serr 1 2`.
- Expected under this audit: only the case-insensitive closure of the supported
  error-command grammar is required.
- Proof obligations: PO-001 and PO-006.
- V1 status: no source change. A broader QDP command language would need a
  separate public requirement and parser design.

## F-004: Existing uppercase behavior and API compatibility are preserved

- Classification: compatibility confirmation.
- Evidence: E3 and E5.
- Input: documented uppercase commands, public reader calls, and writer calls.
- Observed in V1 by source inspection: only the command regex was relaxed for
  command-word case; signatures and writer output are unchanged.
- Expected: existing uppercase QDP files and public API paths continue to work.
- Proof obligations: PO-004 and PO-005.
- V1 status: satisfied without further source edits.

## F-005: Proof and test caveat

- Classification: proof capability and test gap.
- Evidence: FVK honesty gate and benchmark no-exec instruction.
- Observed: the proof artifacts were constructed but `kompile`, `kprove`,
  Python, and tests were not run.
- Expected: keep all tests until the emitted commands are machine-checked;
  add public coverage for lowercase/mixed-case supported commands in a normal
  development environment.
- Proof obligation: PO-006.
- V1 status: source remains unchanged; no tests were modified.
