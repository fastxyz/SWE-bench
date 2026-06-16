# Public Compatibility Audit

## Changed Public Symbols

`flask.Blueprint.__init__`

- Signature changed: no.
- Return shape changed: constructor still returns a blueprint object on valid input.
- New behavior: `name == ""` raises `ValueError`.
- Compatibility status: intentional public behavior change required by the issue.

`flask.Blueprint.register`

- Signature changed: no.
- Public caller shape changed: no.
- New behavior: effective registration name `""` raises `ValueError`.
- Compatibility status: intentional public behavior change for the same empty-name defect.

`flask.Flask.register_blueprint`

- Signature changed: no.
- Implementation changed: no.
- Compatibility status: delegates to `Blueprint.register`; observes the new `ValueError` for `name=""`.

`flask.Blueprint.register_blueprint`

- Signature changed: no.
- Implementation changed: no.
- Compatibility status: nested options are still recorded; empty nested names are rejected when effective registration reaches `Blueprint.register`.

## Overrides and Virtual Dispatch

No new virtual-method arguments, callback shapes, or storage formats were introduced. Existing subclass overrides of `make_setup_state` still receive the same arguments and are not reached on the newly invalid empty-name path.

