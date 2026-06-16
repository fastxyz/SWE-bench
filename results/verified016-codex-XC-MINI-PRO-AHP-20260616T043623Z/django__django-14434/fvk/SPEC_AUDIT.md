# Spec Audit

Status: constructed, not machine-checked.

## Adequacy Gate

C-001 vs I-001, I-002, E-001 through E-004: pass.

The claim states the core public intent: a unique statement with an explicit name must still report references to its unique columns. This is the path where the `columns` part is required because the name is a quoted string.

C-002 vs I-001, I-002, E-001 through E-004: pass.

Generated names are also covered. This prevents the proof from only covering the explicit-name reproducer.

C-003 vs I-005 and E-002: pass as a counterexample, not as a preserved behavior.

The formal V1 claim documents the reported bug shape. It is not used as a desired postcondition.

C-004 vs I-003 and E-005: pass.

The formal frame condition says the SQL rendering table part remains a table placeholder over the raw table key. It does not require `Columns` to store the wrapper.

## Ambiguities

No public-intent ambiguity remains for the audited path. The issue explicitly names the wrong argument type and the intended consumer behavior.

## Scope Limits

The K model does not formalize actual SQL rendering, query compilation, backend feature gates, or expression-column extraction. Those are outside the reported defect and are handled as compatibility/frame conditions in `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

