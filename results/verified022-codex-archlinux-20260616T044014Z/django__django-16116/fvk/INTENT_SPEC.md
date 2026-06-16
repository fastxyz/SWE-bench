# Intent Spec

Status: constructed, not machine-checked.

## Public-intent obligations

I1. `makemigrations --check` is a check-only command mode. If model changes
would require migrations, it must report failure by exiting with a non-zero
status.

I2. `makemigrations --check` must not create, update, or delete migration files
as part of reporting missing migrations. In this audit, "making migrations"
means the file-system effects used by `makemigrations`: creating migration
directories or `__init__.py` files, writing migration files, deleting previous
migration files during `--update`, or formatting written migration files.

I3. `makemigrations --check` may still log the migrations that would be made.
The issue explicitly allows check commands to exit after "possibly logging a
bit".

I4. If no missing migrations are detected, `makemigrations --check` should
complete successfully and still not make migration files.

I5. Existing non-check behavior is a frame condition: normal `makemigrations`
and explicit `--dry-run` behavior should not be changed except for the intended
documentation/help text clarification.

I6. No public Python API shape should change. The relevant public interface is
the management command option behavior, not the internal helper signatures.

## Domain and assumptions

A1. The proof domain starts after ordinary command validation, migration graph
loading, consistency checks, and autodetection have produced abstract command
facts: whether changes exist, whether the command is on the normal, `--update`,
`--empty`, or merge-write path, and whether conflicts route to merge handling.

A2. Error paths that happen before migration writing, such as invalid app
labels, inconsistent history, missing last migration for `--update`, or merge
conflicts without `--merge`, are outside the exit-status claims. They are still
inside the no-migration-write frame because they do not reach the writer.

A3. The issue does not require exact stdout/stderr contents. Output is modeled
only as an allowed side effect, not as a postcondition.

