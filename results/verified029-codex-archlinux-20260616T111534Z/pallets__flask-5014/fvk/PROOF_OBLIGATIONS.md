# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Constructor Empty Name Raises

Claim: For `Blueprint.__init__`, if `name == ""`, execution reaches a `ValueError` result before `self.name` is assigned.

Intent evidence: E1.

K claim: `C-INIT-EMPTY`.

Finding trace: F-001.

## PO-2: Constructor Non-Empty Valid Name Preserves Initialization

Claim: For `Blueprint.__init__`, if `name != ""` and the existing dotted-name predicate is false, execution reaches the normal initialization path and records `self.name = name`.

Intent evidence: E2 plus frame condition from existing public behavior.

K claim: `C-INIT-NONEMPTY`.

Finding trace: F-001, NF-001.

## PO-3: Constructor Dotted Name Behavior Remains

Claim: For `Blueprint.__init__`, if `name != ""` and `name` contains `.`, execution reaches the existing `ValueError` branch for dotted names.

Intent evidence: E3.

K claim: `C-INIT-DOTTED`.

Finding trace: F-001.

## PO-4: Empty Effective Registration Name Raises Before Mutation

Claim: For `Blueprint.register`, let `self_name = options.get("name", self.name)`. If `self_name == ""`, execution reaches a `ValueError` result before `app.blueprints` is updated, `_got_registered_once` is set, setup state is created, deferred functions run, CLI commands are registered, or nested blueprints are registered.

Intent evidence: E1, E4, E5.

K claims: `C-REGISTER-EMPTY-OVERRIDE`, `C-REGISTER-EMPTY-DEFAULT`.

Finding trace: F-002, F-003.

## PO-5: Non-Empty Effective Registration Name Preserves Existing Register Behavior

Claim: For `Blueprint.register`, if `self_name != ""`, the inserted empty-name guard falls through and the existing duplicate-name and registration behavior is unchanged by the V1 patch.

Intent evidence: E2, E4, frame condition.

K claim: `C-REGISTER-NONEMPTY-NOCONFLICT`.

Finding trace: F-002, NF-002.

## PO-6: Nested Blueprint Effective Registration Uses PO-4

Claim: Nested registration eventually calls `blueprint.register(app, bp_options)` for the child. Therefore an empty nested `name` option is rejected by PO-4 when the nested registration is applied.

Intent evidence: E2, E4, implementation call graph.

K coverage: Modeled as the same `registerBlueprint(..., withName(""), ...)` transition used in PO-4.

Finding trace: F-003.

## PO-7: Public Compatibility Frame

Claim: The patch changes only validation behavior for the newly invalid empty-string name. It does not change public method signatures, return shapes, callback protocols, or test files.

Intent evidence: issue asks for a new `ValueError`; public docs expose the same constructor and registration APIs.

K coverage: Frame condition in `C-INIT-NONEMPTY` and `C-REGISTER-NONEMPTY-NOCONFLICT`; human compatibility audit in `PUBLIC_COMPATIBILITY_AUDIT.md`.

Finding trace: NF-001, NF-002.

