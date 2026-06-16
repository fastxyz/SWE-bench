# PROOF OBLIGATIONS

Status: constructed obligations for V1; no formal tooling was run.

## PO-1: Same-table no-op dominates all database side effects

- Claim: `RENAME-MODEL-NOOP-SAME-TABLE`
- Precondition: `AllowMigrate = true`, `SameTable = true`, `RelatedCount >= 0`, `M2MCount >= 0`.
- Required postcondition: `<dbops>` unchanged.
- Code evidence: `models.py` lines 323-332 return before `alter_db_table()`, related `alter_field()`, and M2M loops.
- Finding trace: F-001, F-002, F-004.
- Status: discharged by source inspection and constructed proof.

## PO-2: Disallowed migration remains a no-op

- Claim: `RENAME-MODEL-NOOP-DISALLOWED`
- Precondition: `AllowMigrate = false`.
- Required postcondition: `<dbops>` unchanged.
- Code evidence: the body remains under `if self.allow_migrate_model(...)`.
- Finding trace: F-003.
- Status: discharged by source inspection and constructed proof.

## PO-3: Different-table behavior is preserved

- Claim: `RENAME-MODEL-DIFFERENT-TABLE-PRESERVES-WORK`
- Precondition: `AllowMigrate = true`, `SameTable = false`, `RelatedCount >= 0`, `M2MCount >= 0`.
- Required postcondition: `<dbops>` increases by `1 + RelatedCount + 2 * M2MCount`.
- Code evidence: V1 only adds an early return in the same-table branch and reuses local variables in the existing direct table rename call.
- Finding trace: F-003.
- Status: discharged by source inspection and constructed proof.

## PO-4: State migration behavior is preserved

- Claim type: frame condition, not a database side-effect K claim.
- Precondition: any `RenameModel.state_forwards()` call.
- Required postcondition: state still delegates to `state.rename_model(app_label, old_name, new_name)`.
- Code evidence: `models.py` lines 316-317 unchanged.
- Finding trace: F-002.
- Status: discharged by source inspection.

## PO-5: Public API compatibility is preserved

- Claim type: compatibility audit.
- Precondition: callers invoke `database_forwards(app_label, schema_editor, from_state, to_state)`.
- Required postcondition: signature, call protocol, operation serialization, and state API are unchanged.
- Code evidence: no signature or public attribute changes.
- Finding trace: F-003.
- Status: discharged by `PUBLIC_COMPATIBILITY_AUDIT.md`.

## PO-6: Adequacy of formal claims

- Claim type: FVK adequacy gate.
- Required postcondition: formal English claims match public intent and do not prove legacy buggy behavior.
- Evidence: `SPEC_AUDIT.md` marks all claims pass.
- Finding trace: F-001, F-005.
- Status: discharged for constructed proof; machine-check remains pending.
