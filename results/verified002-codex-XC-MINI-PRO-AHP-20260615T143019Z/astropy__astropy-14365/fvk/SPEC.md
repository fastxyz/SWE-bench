# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for the QDP reader issue in
`repo/astropy/io/ascii/qdp.py`. The verified observable is the QDP command
classification and downstream error-command normalization needed for
`Table.read(..., format="ascii.qdp")` to accept lowercase supported error
commands.

This is not a full formalization of all of Astropy or all of QDP. The public
issue, local QDP docs, and current reader define the relevant supported command
family as `READ SERR` and `READ TERR` with integer column arguments.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E1 | prompt | "QDP itself is not case sensitive and ... can use `read serr 1 2`" | Supported QDP error commands are recognized independently of ASCII case. | Encoded in PO-001. |
| E2 | prompt | "should read into a `Table` with errors, rather than crashing" | `read serr 1 2` must classify as a command and feed symmetric-error specs for columns 1 and 2. | Encoded in PO-002 and PO-003. |
| E3 | source docs | QDP examples use `READ TERR 1` and `READ SERR 3` for error columns. | Preserve uppercase command behavior and cover both supported error command forms. | Encoded in PO-001 and PO-004. |
| E4 | implementation | `_get_tables_from_qdp_file` stores `err_specs[command[1].lower()]`. | Once command classification succeeds, mixed/lowercase `SERR`/`TERR` tokens normalize to `serr`/`terr`. | Encoded in PO-003. |
| E5 | implementation/callsites | `QDP.read` -> `_read_table_qdp` -> `_get_tables_from_qdp_file` -> `_line_type`; no signature change is needed. | Public reader/writer API and producer/consumer shapes are preserved. | Encoded in PO-005. |
| E6 | prompt/docs ambiguity | "all commands" is broad, but the concrete issue and local docs are about error-column commands. | Do not infer support for unrelated QDP directives without further public evidence. | Recorded as F-003. |

## Intended Contract

For every supported QDP error-command line in the existing grammar:

```text
READ SERR <integer-column>...
READ TERR <integer-column>...
```

the `READ`, `SERR`, and `TERR` command words are matched case-insensitively.
If the line is a case variant such as `read serr 1 2`, `_line_type()` returns
`command` rather than raising `ValueError`.

When `_get_tables_from_qdp_file()` later processes accepted command lines, the
error command token is normalized to the canonical lowercase key used by
`_interpret_err_lines`: `serr` for symmetric errors and `terr` for two-sided
errors.

## Frame Conditions

- Uppercase `READ SERR` and `READ TERR` command lines remain valid.
- Existing data/comment/new-line classification behavior is unchanged.
- Invalid non-QDP gibberish remains invalid.
- `QDP.read`, `_read_table_qdp`, `_get_tables_from_qdp_file`, `_line_type`, and
  the QDP writer signatures are unchanged.
- The writer may continue emitting uppercase commands.

## Formal Artifacts

- `fvk/mini-qdp.k`: mini semantics for tokenized QDP line classification and
  error-key normalization.
- `fvk/qdp-command-spec.k`: K reachability claims for the command
  case-insensitivity and normalization obligations.
- Adequacy artifacts: `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`,
  `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, and
  `PUBLIC_COMPATIBILITY_AUDIT.md`.
