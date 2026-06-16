# FVK Specification: Blueprint Empty Name Validation

Status: constructed, not machine-checked.

## Scope

Audited source unit: `repo/src/flask/blueprints.py`.

Functions in scope:

- `Blueprint.__init__`
- `Blueprint.register`

No loops or recursion are involved. The proof is a finite branch proof over string equality and name-option resolution. `Flask.register_blueprint` is included as a caller compatibility path because it delegates to `Blueprint.register`.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Require a non-empty name for Blueprints" and "It would be helpful if a `ValueError` was raised" | A blueprint name must not be the empty string. Attempting to create or effectively register one must raise `ValueError`. | Encoded by PO-1 and PO-4. |
| E2 | `repo/docs/blueprints.rst` | The blueprint constructor name prefixes endpoint names, separated by a dot. | A blueprint name is an endpoint namespace contributor, not display-only text. Empty names collapse namespace prefixing. | Encoded by registration obligations. |
| E3 | `repo/CHANGES.rst` | A dot has special meaning because it separates nested blueprint names and endpoint names. | Existing dotted-name rejection remains a frame condition; the empty-name fix must not weaken it. | Encoded by PO-3. |
| E4 | `repo/CHANGES.rst` and `Blueprint.register` docs | `register_blueprint` has a `name=` option to change the pre-dotted registration name. | `name=""` during registration is another way to give a blueprint an empty effective name. | Encoded by PO-4. |
| E5 | implementation | `name = f"{name_prefix}.{self_name}".lstrip(".")` and `state.add_url_rule` prefixes endpoints with `self.name_prefix`, `self.name`, and `endpoint`. | The bug occurs before endpoint registration when `self_name == ""`; rejecting there prevents empty app keys and unprefixed endpoints. | Used as implementation evidence, not as intent. |

## Contract

### C1: Constructor Name Validation

For every call to `Blueprint.__init__` in the valid constructor domain where `import_name` and path arguments do not fail independently:

- If `name == ""`, the constructor raises `ValueError`.
- If `name != ""`, the new empty-name guard does not change the existing dotted-name check.
- If `name != ""` and `name` does not contain `.`, the constructor records `self.name = name` and proceeds with the existing initialization behavior.

### C2: Effective Registration Name Validation

For every effective registration through `Blueprint.register(app, options)`:

- Let `self_name = options.get("name", self.name)`.
- If `self_name == ""`, registration raises `ValueError` before computing the final dotted name, mutating `app.blueprints`, marking `_got_registered_once`, creating setup state, adding static routes, merging callbacks, registering CLI commands, or registering nested blueprints.
- If `self_name != ""`, the inserted guard falls through and preserves the existing duplicate-name, effective-name, setup-state, callback, CLI, and nested-blueprint behavior.

### C3: Nested Registration Coverage

Nested blueprints are recorded by `Blueprint.register_blueprint`, then become effective through `blueprint.register(app, bp_options)` during parent registration. Therefore C2 applies to `name=""` in nested `bp_options` when the nested registration is actually applied to the app.

## Frame Conditions

- No public method signatures change.
- Existing `ValueError` behavior for dotted constructor names remains.
- Existing behavior for non-empty names remains.
- The spec does not require new validation for whitespace-only names, non-string values, or dotted `name=` registration overrides; those are not part of the public issue intent.

