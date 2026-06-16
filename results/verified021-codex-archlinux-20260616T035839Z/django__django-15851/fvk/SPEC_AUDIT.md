# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item(s) | Result | Notes |
| --- | --- | --- | --- |
| C-DBNAME | I-01, I-02, D-01, D-02 | PASS | Directly states the issue's required PostgreSQL ordering. |
| C-DEFAULT-POSTGRES | I-01, I-02, D-01 | PASS | The code-created default `postgres` value is a positional database argument, so the same ordering rule applies. |
| C-SERVICE-NO-DBNAME | D-03, IE-09 | PASS | No dbname exists in this branch, so the frame requirement is to keep no positional dbname. |
| F-ENV | I-04 | PASS | V1 moves only `args.extend(parameters)` and does not alter environment construction. |
| F-COMPAT | I-05, IE-05, IE-06 | PASS | No public signature, caller, return shape, or backend dispatch API changed. |
| Public `test_parameters` legacy order | IE-07 | SUSPECT | The public test expects `dbname` before `--help`, which conflicts with the issue's explicit ordering requirement. |

No adequacy failure was found. The formal claims cover the full behavior space
for the reported ordering defect: dbname present, default dbname synthesized,
and service-only no-dbname.
