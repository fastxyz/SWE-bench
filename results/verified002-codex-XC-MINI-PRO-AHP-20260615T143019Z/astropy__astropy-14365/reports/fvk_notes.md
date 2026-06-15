# FVK Notes

## Decision summary

V1 stands unchanged. The FVK audit found that the source change already matches
the public intent for the supported QDP error-command grammar.

## Decisions traced to findings and proof obligations

- Kept the scoped inline regex flag in `_line_type()`.
  - Finding: F-001 identifies the original bug as rejection of lowercase
    supported QDP commands.
  - Obligations: PO-001 and PO-002 require case-insensitive classification and
    the exact `read serr 1 2` witness.
  - Decision: no further code edit is needed because
    `(?i:READ [TS]ERR)` discharges those obligations.

- Kept downstream command parsing unchanged.
  - Finding: F-002 confirms that accepted command tokens are already normalized
    with `command[1].lower()`.
  - Obligation: PO-003 requires canonical `serr` and `terr` keys.
  - Decision: no source edit is needed in `_get_tables_from_qdp_file()`.

- Did not expand the parser to unrelated QDP directives.
  - Finding: F-003 records the ambiguity in the broad phrase "all commands".
  - Obligations: PO-001 and PO-006 scope the proof to the case-insensitive
    closure of the existing supported `READ SERR` / `READ TERR` grammar.
  - Decision: no broader parser change is justified by the concrete issue,
    local docs, or current reader contract.

- Preserved writer behavior and public API shape.
  - Finding: F-004 confirms that uppercase behavior and API compatibility are
    unchanged.
  - Obligations: PO-004 and PO-005 require the frame and compatibility
    conditions.
  - Decision: no edits were made to writer code, signatures, return types, or
    public dispatch paths.

- Did not modify tests or run verification commands.
  - Finding: F-005 records the proof/test caveat.
  - Obligation: PO-006 requires the honesty gate.
  - Decision: the proof artifacts are labeled constructed, not machine-checked,
    and no tests, Python, `kompile`, or `kprove` were run.

## Artifacts produced

- Required FVK files: `fvk/SPEC.md`, `fvk/FINDINGS.md`,
  `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and
  `fvk/ITERATION_GUIDANCE.md`.
- Formal core and adequacy files: `fvk/mini-qdp.k`,
  `fvk/qdp-command-spec.k`, `fvk/INTENT_SPEC.md`,
  `fvk/PUBLIC_EVIDENCE_LEDGER.md`, `fvk/FORMAL_SPEC_ENGLISH.md`,
  `fvk/SPEC_AUDIT.md`, and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
