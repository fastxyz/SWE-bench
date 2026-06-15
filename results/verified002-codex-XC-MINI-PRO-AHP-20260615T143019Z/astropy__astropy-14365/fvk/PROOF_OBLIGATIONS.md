# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Case-insensitive supported command classification

- Claim: for any supported QDP error-command line whose command tokens are a
  case variant of `READ SERR` or `READ TERR`, `_line_type()` returns `command`.
- Public evidence: E1 and E3.
- Formal claim: `LINE-TYPE-CASE-INSENSITIVE-READ-ERR`.
- V1 discharge: `_command_re` uses the scoped inline flag
  `(?i:READ [TS]ERR)`, making the command words case-insensitive while leaving
  the rest of the line grammar intact.

## PO-002: Exact issue witness

- Claim: the concrete line `read serr 1 2` is accepted as a command and does
  not produce the reported `ValueError`.
- Public evidence: E2.
- Formal claim: `LINE-TYPE-LOWERCASE-SERR-WITNESS`.
- V1 discharge: `read serr` matches the scoped case-insensitive command group,
  and the two integer column arguments match the existing numeric argument
  pattern.

## PO-003: Error-spec key normalization

- Claim: after command classification succeeds, `SERR` and `TERR` tokens of any
  accepted case variant become downstream keys `serr` and `terr`.
- Public evidence: E2 and E4.
- Formal claims: `ERR-SPEC-KEY-SERR-NORMALIZED` and
  `ERR-SPEC-KEY-TERR-NORMALIZED`.
- V1 discharge: `_get_tables_from_qdp_file` already uses
  `command[1].lower()`, so no additional source edit is required.

## PO-004: Frame preservation for existing line classes

- Claim: uppercase supported commands remain commands, and non-command
  categories are not reclassified by the fix.
- Public evidence: E3.
- Formal claims: `LINE-TYPE-UPPERCASE-SERR-FRAME` plus the frame conditions in
  `SPEC.md`.
- V1 discharge: the regex change only relaxes the command words' case; the
  data, comment, new-line, and invalid-line alternatives are unchanged.

## PO-005: Public compatibility

- Claim: no public reader/writer signature, dispatch path, return category, or
  output storage shape changes.
- Public evidence: E5.
- Formal artifact: `PUBLIC_COMPATIBILITY_AUDIT.md`.
- V1 discharge: only `_command_re` and a docstring example changed in source;
  no API or writer code changed.

## PO-006: Adequacy and honesty gate

- Claim: the formal claims match public intent and are labeled with the correct
  proof status.
- Public evidence: FVK method docs and all ledger entries.
- Formal artifacts: `INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`,
  `SPEC_AUDIT.md`, `mini-qdp.k`, `qdp-command-spec.k`, and `PROOF.md`.
- V1 discharge: `SPEC_AUDIT.md` marks the required command-case obligations as
  pass. The proof is explicitly labeled constructed, not machine-checked.
