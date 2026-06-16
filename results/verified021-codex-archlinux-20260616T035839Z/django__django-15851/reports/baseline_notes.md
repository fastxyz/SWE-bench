# Baseline Notes

## Root cause

`django.db.backends.postgresql.client.DatabaseClient.settings_to_cmd_args_env()`
constructed the `psql` command as connection options, then the database name,
then any additional parameters passed through `manage.py dbshell -- ...`.
PostgreSQL's `psql` expects command-line options before the optional database
name, so parameters such as `-c "select ..."` were interpreted as extra
positional arguments and ignored after Django had already appended the dbname.

## Changed files

`repo/django/db/backends/postgresql/client.py`

Moved `args.extend(parameters)` before appending `dbname`. The generated command
now keeps Django's configured `-U`, `-h`, and `-p` options first, places any
user-supplied `dbshell` parameters next, and leaves the resolved database name
as the final positional argument for `psql`.

## Assumptions and alternatives considered

I assumed the issue is PostgreSQL-specific because the reported behavior and
the command semantics are for `psql`; other backends have different client
syntax and were left unchanged.

I considered changing the management command to reorder parameters globally,
but rejected that because it would affect SQLite, MySQL, and Oracle argument
ordering without evidence that their client CLIs need the same behavior.

I also considered replacing the positional database name with `-d dbname`, but
that would be a broader behavioral change than necessary. Keeping the database
name positional and moving it to the end directly addresses the reported `psql`
argument parsing issue.
