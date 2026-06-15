# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kprove`, Python, or
tests were run.

## What Is Proved

For the supported QDP error-command grammar used by this reader, command words
`READ`, `SERR`, and `TERR` are accepted independently of ASCII case. In
particular, `read serr 1 2` is classified as a command, and the downstream
error-spec key is normalized to `serr`.

The proof establishes partial correctness for the audited parser slice. There
is no loop or termination proof obligation in this slice.

## Proof Sketch

1. `_line_type()` strips the line and matches it against `_type_re`.
2. V1 changes the command sub-pattern from `READ [TS]ERR...` to
   `(?i:READ [TS]ERR)...`.
3. The inline flag is scoped to the command words, so a token sequence such as
   `read serr` or `Read Terr` matches the same command alternative as
   `READ SERR` or `READ TERR`.
4. Once the named `command` group matches, `_line_type()` returns `command`
   before reaching the error path. Therefore the issue witness no longer raises
   `ValueError: Unrecognized QDP line: read serr 1 2`.
5. `_get_tables_from_qdp_file()` records command lines and, on the first data
   row, splits each command line and computes `command[1].lower()`. Therefore
   accepted case variants of `SERR` and `TERR` flow to canonical keys `serr`
   and `terr`.
6. The data/comment/new/invalid alternatives are unchanged, and the writer path
   is untouched, so the compatibility frame obligations hold by inspection.

## K Claim Mapping

- PO-001 maps to `LINE-TYPE-CASE-INSENSITIVE-READ-ERR`.
- PO-002 maps to `LINE-TYPE-LOWERCASE-SERR-WITNESS`.
- PO-003 maps to `ERR-SPEC-KEY-SERR-NORMALIZED` and
  `ERR-SPEC-KEY-TERR-NORMALIZED`.
- PO-004 maps to `LINE-TYPE-UPPERCASE-SERR-FRAME` and the unchanged mini-QDP
  non-command rules.

The K model is intentionally focused on tokenized command classification. It
does not model the entire Python `re` engine; the proof obligation for the
source patch is the correspondence between the scoped inline case-insensitive
regex group and the `ciEq` command-token predicate in `mini-qdp.k`.

## Commands To Machine-Check Later

These commands are written as artifacts only and were not executed:

```sh
kompile fvk/mini-qdp.k --backend haskell
kast --backend haskell fvk/qdp-command-spec.k
kprove fvk/qdp-command-spec.k
```

Expected machine-check result: `#Top` for all claims.

## Test Recommendation

- Add or keep a test that reads the exact issue witness:
  `read serr 1 2` followed by `1 0.5 1 0.5`.
- Add or keep a mixed-case `READ TERR`/`read terr` test for parity.
- Keep existing uppercase QDP tests.
- Do not remove tests based on this constructed proof unless the emitted K
  commands are run and return `#Top`.
