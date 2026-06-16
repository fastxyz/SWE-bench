# Public Evidence Ledger

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt issue | "database client runshell doesn't respect os.environ values in some cases" | The observable `runshell()` subprocess environment must inherit `os.environ` when no overrides are supplied. | Encoded in PO-RUNSHELL-NONE and PO-RUNSHELL-EMPTY. |
| E2 | prompt issue | "postgresql client returns empty dict instead of None for env" | PostgreSQL `settings_to_cmd_args_env()` must return `None` for the no-overrides case. | Encoded in PO-PG-NO-OVERRIDES. |
| E3 | prompt issue | "as a result os.environ is not used and empty env passed to subprocess" | Passing `{}` to `subprocess.run(env=...)` is the defect; empty mappings must normalize to `None` before the subprocess call. | Encoded in PO-RUNSHELL-EMPTY and Finding F1. |
| E4 | docs | "`DatabaseClient.runshell()` now gets arguments and an optional dictionary with environment variables ... from `settings_to_cmd_args_env()`." | The env component is optional; no environment overrides are represented as `None`, while mappings represent actual variables to add. | Encoded in the domain of all proof obligations. |
| E5 | sibling backends | MySQL initializes `env = None`; SQLite and Oracle return `None` for no env overrides. | Returning `None` for no overrides is consistent with built-in backend precedent. | Supports PO-PG-NO-OVERRIDES. |
| E6 | public tests | PostgreSQL visible tests expected `{}` in `test_nopass` and `test_parameters`. | These tests encode the pre-fix behavior that the issue identifies as buggy, so they are SUSPECT legacy evidence and cannot veto E1-E3. | Recorded as Finding F2. |
| E7 | code | Base runner merges only truthy env mappings and passes the resulting value to `subprocess.run()`. | If a falsey mapping reaches the base runner, it must be normalized to `None` to satisfy E1/E3. | Drives the V2 base runner edit and PO-RUNSHELL-EMPTY. |
| E8 | code | PostgreSQL builds `env = {}` and conditionally adds PostgreSQL keys. | If no keys are added, the function's env result must normalize to `None`; otherwise it must remain the populated mapping. | Drives the V1/V2 PostgreSQL edit and PO-PG-NO-OVERRIDES/PO-PG-WITH-OVERRIDES. |
