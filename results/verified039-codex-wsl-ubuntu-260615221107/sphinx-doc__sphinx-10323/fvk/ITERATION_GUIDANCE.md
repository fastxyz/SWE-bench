# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

## Why

F2 confirms that the V1 filter order discharges the core issue obligations PO1 and PO2. F3 and F4 confirm that the relevant frame obligations PO3 and PO5 are preserved. PO6 confirms that no public compatibility repair is needed.

## No source edits in this FVK pass

The audit did not identify a stronger source change justified by public intent. Recovering leading whitespace already stripped by docutils is explicitly out of scope by F6 and PO8. Changing option parsing or directive syntax would exceed the public-intent repair and add compatibility risk without evidence that Sphinx can recover the discarded whitespace.

## Recommended future tests

Do not modify tests in this benchmark task. For a normal development follow-up, add a public regression test that constructs a `LiteralIncludeReader` or Sphinx fixture using `dedent` with `prepend` and `append`, then asserts:

- included file lines are dedented;
- prepended/appended lines are not stripped by dedent;
- no `non-whitespace stripped by dedent` warning is caused by synthetic option text.

## Machine-checking follow-up

Run the commands listed in `fvk/PROOF.md` in an environment with K installed. Until they return `#Top`, the proof remains constructed, not machine-checked, and no test-removal recommendation should be acted on.
