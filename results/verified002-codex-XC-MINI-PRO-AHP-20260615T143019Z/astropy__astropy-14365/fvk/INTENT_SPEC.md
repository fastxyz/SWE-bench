# Intent Spec

Status: constructed for FVK audit; not machine-checked.

## Required behavior

1. QDP error command keywords are case-insensitive for the commands supported by
   this reader, namely `READ SERR` and `READ TERR`.
2. A file whose first line is `read serr 1 2` and whose data row has matching
   error columns must be accepted as a QDP table with symmetric-error
   specifications for data columns 1 and 2. It must not fail with
   `ValueError: Unrecognized QDP line: read serr 1 2`.
3. Existing uppercase command files, including documented `READ SERR` and
   `READ TERR` examples, must continue to be accepted.
4. The reader's public API shape is preserved: `QDP.read`, `Table.read(...,
   format="ascii.qdp")`, `_line_type(line, delimiter=None)`, and the writer
   behavior are not changed by the fix.

## Domain

The audited domain is the case-insensitive closure of the reader's existing QDP
error-command grammar: a `READ` token, an error-command token `SERR` or `TERR`,
and one or more integer column numbers. The audit does not claim support for
other QDP directives or for a broader command language not described by the
issue, the local docs, or the existing reader.

## Frame conditions

- Non-command line categories (`comment`, `data`, `new`, and invalid gibberish)
  keep their existing classification rules.
- The writer may continue to emit uppercase `READ SERR` and `READ TERR`.
- The downstream error-spec dictionary remains keyed by lowercase `serr` and
  `terr`, as consumed by `_interpret_err_lines`.
