# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-01: `S102` Accepts Explicit `builtins.exec`

- Claim: `check(S102, qname("builtins", "exec"), INFO)` reaches `emit`.
- Source link: `exec_used.rs` matches `["" | "builtins", "exec"]`.
- Finding link: F-01.
- Status: discharged by V1.

## PO-02: `S102` Preserves Unqualified `exec`

- Claim: `check(S102, qname("", "exec"), INFO)` reaches `emit`.
- Source link: the empty segment remains in `["" | "builtins", "exec"]`; `SemanticModel` documents this as a builtin binding.
- Finding link: no defect; this is a frame condition from E4.
- Status: discharged by V1.

## PO-03: `S102` Rejects `builtin.exec`

- Claim: `check(S102, qname("builtin", "exec"), INFO)` reaches `noEmit`.
- Source link: `"builtin"` is no longer an accepted segment.
- Finding link: F-02.
- Status: discharged by V1.

## PO-04: `PTH123` Accepts Explicit `builtins.open` When Compatible

- Claim: `check(PTH123, qname("builtins", "open"), openInfo(false, false, false))` reaches `emit`.
- Source link: `replaceable_by_pathlib.rs` matches `["" | "builtins", "open"]` before returning `BuiltinOpen`.
- Finding link: F-01.
- Status: discharged by V1.

## PO-05: `PTH123` Preserves Unqualified `open`

- Claim: `check(PTH123, qname("", "open"), openInfo(false, false, false))` reaches `emit`.
- Source link: the empty segment remains in `["" | "builtins", "open"]`; `SemanticModel` documents this as a builtin binding.
- Finding link: no defect; this is a frame condition from E4.
- Status: discharged by V1.

## PO-06: `PTH123` Rejects `builtin.open`

- Claim: `check(PTH123, qname("builtin", "open"), openInfo(false, false, false))` reaches `noEmit`.
- Source link: `"builtin"` is no longer an accepted segment.
- Finding link: F-02.
- Status: discharged by V1.

## PO-07: `PTH123` Preserves Compatibility Exclusions

- Claim: `builtins.open` reaches `noEmit` whenever the non-default `closefd`, non-default `opener`, or file-descriptor exclusion is true.
- Source link: V1 did not change the existing exclusion block below the `PTH123` match arm.
- Finding link: F-03.
- Status: discharged by V1.

## PO-08: No Public API or Dispatch Compatibility Regression

- Claim: the fix changes no public function signatures, rule codes, diagnostic messages, or public dispatch protocol.
- Source link: V1 changes only string literals in two private rule implementations.
- Finding link: no defect; compatibility audit in `SPEC.md`.
- Status: discharged by static inspection.

## PO-09: Full Issue Coverage

- Claim: no remaining audited source path still accepts exact module segment `"builtin"` for the affected behavior.
- Source link: static inspection found no exact `"builtin"` literal in the relevant linter, semantic, AST, and stdlib source paths after V1.
- Finding link: F-04.
- Status: discharged by static inspection.
