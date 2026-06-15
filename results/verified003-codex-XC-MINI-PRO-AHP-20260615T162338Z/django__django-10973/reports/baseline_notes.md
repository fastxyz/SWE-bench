# Baseline Notes

## Root cause

`django.db.backends.postgresql.client.DatabaseClient.runshell_db()` passed the
database password to `psql` by creating a temporary `.pgpass` file, pointing the
process at it through `os.environ['PGPASSFILE']`, and cleaning that global
environment variable afterward. This made the implementation more complex than
necessary and relied on process-global environment mutation while preparing the
client subprocess.

## Changed files

`repo/django/db/backends/postgresql/client.py`

- Removed the temporary `.pgpass` file creation path, including the escaping
  helper and `NamedTemporaryFile` import that only existed for that path.
- Built a copied environment for the client process, set `PGPASSWORD` in that
  environment when a password is configured, and passed it directly to
  `subprocess.run()`.
- Switched the shell invocation from `subprocess.check_call()` to
  `subprocess.run(..., check=True, env=env)` while preserving the existing
  command-line argument construction and SIGINT handler restoration.

## Assumptions and alternatives

- I assumed `conn_params['password']`, when present, is a string value suitable
  for use as a subprocess environment variable, matching Django's database
  connection parameter handling.
- I kept the existing behavior for an empty or missing password: no Django-owned
  `PGPASSWORD` value is added, so `psql` can use its normal interactive or
  inherited-environment behavior.
- I rejected keeping `.pgpass` as a fallback because the issue specifically asks
  to use `subprocess.run()` with `PGPASSWORD`, and retaining both mechanisms
  would preserve the complexity and global environment mutation the change is
  meant to remove.
