# FVK Findings

Status: constructed, not machine-checked.

## F-001: Legacy string slicing failed for three-digit years

- Classification: code bug, resolved by V1.
- Evidence: E-001 and E-002.
- Proof obligations: OBL-002 and OBL-003.
- Input: `Y = 123`.
- Legacy observed behavior: `str(123)[2:] == "3"`.
- Expected behavior: two-digit year `"23"`.
- V1 result by reasoning: `123 % 100 == 23`, and `%02d` renders that as `"23"`.
- Decision: keep the V1 mechanism for this case.

## F-002: The issue describes a boundary family, not one point

- Classification: forgotten corner-case family, resolved by V1.
- Evidence: E-003 and E-004.
- Proof obligations: OBL-002, OBL-003, and OBL-004.
- Inputs to cover: `Y` in `1..99`, `100..999`, and rollover values such as
  `1000`.
- Expected behavior: always exactly two digits for `Y % 100`.
- V1 result by reasoning:
  - `Y = 9` -> `9 % 100 == 9` -> `"09"`
  - `Y = 99` -> `99 % 100 == 99` -> `"99"`
  - `Y = 100` -> `100 % 100 == 0` -> `"00"`
  - `Y = 999` -> `999 % 100 == 99` -> `"99"`
  - `Y = 1000` -> `1000 % 100 == 0` -> `"00"`
- Decision: no additional source edit is needed beyond V1.

## F-003: Ordinary four-digit behavior is preserved

- Classification: compatibility confirmation.
- Evidence: E-006.
- Proof obligations: OBL-005 and OBL-006.
- Input: `Y = 1979`.
- Existing expected behavior: `"79"`.
- V1 result by reasoning: `1979 % 100 == 79`, and `%02d` renders `"79"`.
- Decision: V1 preserves the public test behavior for ordinary years.

## F-004: Public API and frame conditions remain unchanged

- Classification: compatibility confirmation.
- Evidence: E-004, E-006, and source inspection.
- Proof obligations: OBL-006 and OBL-007.
- Observed change: only the body of `DateFormat.y()` changed.
- Expected compatibility: no public signature change; no change to `Y`, other
  tokens, escaping, or dispatch.
- Decision: no compatibility repair is needed.

## F-005: Proof is constructed, not machine-checked

- Classification: proof capability gap, not a code bug.
- Evidence: FVK command constraints and verify honesty gate.
- Proof obligations: OBL-008.
- Input: all modeled cases.
- Observed limitation: K tooling was not run, and the mini semantics abstracts
  Python old-style string formatting to a `pad2()` semantic function.
- Expected mitigation: keep test files unchanged and label test-subsumption
  recommendations as conditional on a future machine check.
- Decision: this does not block keeping V1 because the intent and arithmetic
  derivation are complete, but it limits the proof-confidence claim.

## Summary Verdict

No blocking FVK finding remains against V1. The audit confirms that the V1 code
implements the intent-derived contract for the full Python `datetime` year
domain and preserves the relevant existing public behavior.
