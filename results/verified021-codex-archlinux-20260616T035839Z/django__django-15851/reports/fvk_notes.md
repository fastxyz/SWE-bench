# FVK Notes

## Decision

V1 stands unchanged as the final fix.

The FVK audit confirmed the central issue as Finding F-01 and proof obligation
PO-01: PostgreSQL `dbshell` parameters must precede a configured positional
dbname. V1 already implements that by moving `args.extend(parameters)` before
the `if dbname: args += [dbname]` append in
`repo/django/db/backends/postgresql/client.py`.

## Decisions Traced to Findings and Obligations

1. Kept the V1 source edit unchanged.

   Trace: F-01 and PO-01. The current source constructs the reported case as
   `["psql", "-c", "select * from some_table;", "dbname"]`, matching the issue
   requirement that dbname be left at the end.

2. Did not restore the public test's legacy order.

   Trace: F-02 and PO-01. The existing public PostgreSQL `test_parameters`
   expectation puts `--help` after `dbname`, but the issue explicitly rejects
   parameters-after-dbname ordering. The test is SUSPECT evidence, not a reason
   to revert V1.

3. Kept the default `"postgres"` branch under the same ordering rule.

   Trace: F-03 and PO-02. When Django synthesizes `"postgres"` because both
   `NAME` and service are absent, that value is still a positional database
   argument for `psql`, so it must also follow `parameters`.

4. Made no service-configuration edit.

   Trace: F-04 and PO-03. A service-only configuration has no positional dbname;
   moving `parameters` earlier does not introduce one, and `PGSERVICE` handling
   remains an environment-frame concern.

5. Made no environment, management-command, base-client, or other-backend edit.

   Trace: F-04, F-05, PO-04, PO-05, PO-06, and PO-07. V1 changes only
   PostgreSQL's internal argument ordering and preserves env construction,
   public method signatures, caller behavior, configured option prefix order,
   and non-PostgreSQL backends.

## Verification Caveat

The FVK proof is constructed, not machine-checked. Per the task constraints, I
did not run Django tests, Python, `kompile`, `kast`, or `kprove`; the commands
needed for a later machine check are recorded in `fvk/PROOF.md`.
