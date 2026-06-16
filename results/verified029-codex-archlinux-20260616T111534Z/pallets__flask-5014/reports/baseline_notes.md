# Baseline Notes

## Root Cause

`Blueprint` rejected names containing dots, but it did not reject an empty string. During registration, the effective blueprint name is used as the key in `app.blueprints` and as the prefix for generated endpoints. An empty name collapses the prefix logic, so blueprint routes can be registered as unprefixed application endpoints and request bookkeeping no longer treats them as blueprint endpoints.

The same bad effective name can also be introduced by registering a valid blueprint with `name=""`, because the registration option overrides `self.name` before endpoint names and nested blueprint names are computed.

## Changed Files

`repo/src/flask/blueprints.py`

- Added a `ValueError` in `Blueprint.__init__` when `name == ""`, next to the existing dotted-name validation.
- Added the same `ValueError` in `Blueprint.register` when the effective registration name override is `""`, before the final dotted name is computed.

## Assumptions and Alternatives Considered

- I treated "non-empty name" as specifically rejecting the empty string while preserving existing behavior for other non-string or unusual values as much as this narrow change allows.
- I considered validating only the constructor argument, but rejected that because `app.register_blueprint(bp, name="")` and nested registration options can still create an empty effective blueprint identity.
- I did not add broader validation for whitespace-only names or dotted `name=` overrides because the issue only asks for empty-name rejection, and expanding name semantics would be a larger compatibility change.
- I did not modify tests or run the test suite, per the benchmark instructions.
