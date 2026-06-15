# Public Evidence Ledger

## E1: QDP commands are case-insensitive

- Source: prompt
- Evidence: "QDP itself is not case sensitive and ... can use `read serr 1 2`."
- Obligation: supported QDP command keywords must be recognized regardless of
  ASCII case.
- Status: encoded in `LINE-TYPE-CASE-INSENSITIVE-READ-ERR`.

## E2: Lowercase SERR should read with errors

- Source: prompt
- Evidence: "The following qdp file should read into a `Table` with errors,
  rather than crashing" followed by `read serr 1 2`.
- Obligation: `read serr 1 2` is a command line, not an unrecognized line; its
  error command must become `serr`.
- Status: encoded in `LINE-TYPE-LOWERCASE-SERR-WITNESS` and
  `ERR-SPEC-KEY-SERR-NORMALIZED`.

## E3: Existing supported commands

- Source: docs/source docstring
- Evidence: QDP examples in `astropy/io/ascii/qdp.py` use `READ TERR 1` and
  `READ SERR 3` to describe error columns.
- Obligation: the formal grammar covers the supported error directives
  `READ SERR` and `READ TERR`; uppercase examples remain valid.
- Status: encoded in `LINE-TYPE-UPPERCASE-SERR-FRAME` and
  `LINE-TYPE-MIXEDCASE-TERR`.

## E4: Implementation propagation fact

- Source: implementation
- Evidence: `_get_tables_from_qdp_file` computes
  `err_specs[command[1].lower()] = [int(c) for c in command[2:]]`.
- Obligation: after command classification, mixed/lowercase `SERR` and `TERR`
  tokens flow to canonical `serr` and `terr` keys.
- Status: encoded in `ERR-SPEC-KEY-SERR-NORMALIZED` and
  `ERR-SPEC-KEY-TERR-NORMALIZED`.

## E5: Compatibility surface

- Source: implementation and public callsites
- Evidence: `QDP.read` delegates to `_read_table_qdp`, which delegates to
  `_get_tables_from_qdp_file` and `_line_type`; no signature or return-shape
  change is needed.
- Obligation: preserve public API shape and writer output.
- Status: audited in `PUBLIC_COMPATIBILITY_AUDIT.md`.

## E6: Ambiguous broader QDP command vocabulary

- Source: prompt and docs
- Evidence: the prompt says "all commands" in prose, while the expected
  behavior, local docs, and current reader describe the supported error-column
  commands.
- Obligation: do not infer support for unrelated QDP directives from this issue
  alone.
- Status: recorded as a non-blocking ambiguity in `FINDINGS.md`; no source
  change made.
