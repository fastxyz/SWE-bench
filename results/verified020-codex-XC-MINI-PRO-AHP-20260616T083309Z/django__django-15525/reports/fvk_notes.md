# FVK Notes

## Decision

V1 stands unchanged.

The audit found one public-intent defect, F1, which is the original
non-default-database routing failure. PO-1 and PO-2 show that V1 addresses it by
setting the temporary natural-key probe object's database before
`natural_key()` can follow a relation. PO-3 shows the existing
natural-primary-key manager lookup still uses `db`.

## Source changes

No additional source files were changed during the FVK pass.

`repo/django/core/serializers/base.py` remains as in V1:

- `obj = Model(**data)`
- `obj._state.db = db`
- `natural_key = obj.natural_key()`

This is retained because F1 is discharged by PO-1 and PO-2, while F2 and PO-4
confirm that final construction and non-natural-key branches remain framed.

## Rejected changes

I did not replace the temporary probe construction with `Model.from_db()`.
Finding F3 and PO-6 reject that change: public intent only requires the probe to
carry the target database, while `from_db()` would also alter loaded/addition
state and may invoke custom `from_db()` behavior.

I did not edit `python.py` or `xml_serializer.py`. Finding F4 and PO-5 confirm
their existing call protocol already passes the target database into
`build_instance()`, and V1 did not change the helper signature or return shape.

I did not modify tests. Finding F5 records the regression test that should be
added in normal development, but the task forbids test edits.

## Verification status

The FVK proof is constructed, not machine-checked. The commands to run later are
recorded in `fvk/SPEC.md`, `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md`.
Because K tooling was not run and tests are forbidden here, no test-removal
recommendation is made.
