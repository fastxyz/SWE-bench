# Intent Spec

Status: constructed, not machine-checked.

## Required Behavior

I-01. PostgreSQL `dbshell` additional parameters passed after `manage.py dbshell --`
must be placed before the positional database name when Django invokes `psql`.

I-02. If Django supplies a positional PostgreSQL database name, that database
name must be left at the end of the generated `psql` argument list.

I-03. The configured PostgreSQL connection options that already precede the
database name, such as `-U`, `-h`, and `-p`, remain supported and are not the
source of the reported bug.

I-04. Environment variable construction for password, service, passfile, and SSL
options must remain unchanged because the issue concerns argument ordering, not
environment handling.

I-05. Other database backends are outside the PostgreSQL-specific intent and
must not be changed without separate evidence.

## Domain Assumptions

D-01. `parameters` is the list collected by Django's `dbshell` management command
after `--` and is intended to be passed through to the PostgreSQL `psql` command.

D-02. The order-critical members of `parameters` are PostgreSQL command-line
options and their values, such as `-c` followed by a SQL string.

D-03. Service-based PostgreSQL configurations with no `NAME` use `PGSERVICE` and
do not require a positional database name.
