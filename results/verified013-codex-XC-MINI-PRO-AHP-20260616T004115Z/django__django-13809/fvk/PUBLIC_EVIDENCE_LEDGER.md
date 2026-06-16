# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Add --skip-checks option to the runserver command." | `runserver` parser accepts `--skip-checks`. | Encoded in SPEC and claim `RUNSERVER-PARSER-HAS-SKIP-CHECKS`. |
| E2 | prompt | "consistent with other management commands performing system checks" | Use existing option spelling, boolean `store_true`, and help wording. | Encoded in source and SPEC. |
| E3 | prompt | "wait 15-20 seconds for each project reload during development" | Skipping must affect the reload/start path where `runserver.inner_run()` explicitly calls checks. | Encoded in claims `INNERRUN-SKIP-CHECKS` and `INNERRUN-NO-SKIP-CHECKS`. |
| E4 | source comment | `runserver.py`: "Validation is called explicitly each time the server is reloaded." | `runserver` cannot rely on `BaseCommand.requires_system_checks` for parser/check behavior. | Supports local parser option and local guard. |
| E5 | source code | `migrate.py` adds `--skip-checks` and guards `self.check(...)` with `if not options['skip_checks']`. | Manual-check commands can add and consume the option themselves. | Supports V1 shape. |
| E6 | source comment | `runserver.py`: "Need to check migrations here, so can't use the requires_migrations_check attribute." | Migration warnings are a separate path and remain enabled. | Encoded in both inner-run claims. |
| E7 | source code | `staticfiles` `runserver.Command.add_arguments()` calls `super().add_arguments(parser)`. | Staticfiles runserver receives the new parser option through inheritance. | Compatibility audit pass. |
| E8 | public tests | `tests/admin_scripts/tests.py` expects `testserver` to pass `skip_checks=True` into `runserver.handle`. | Programmatic callers already treat `skip_checks` as a valid runserver option flow. | Compatibility audit pass. |

No hidden tests, evaluator output, internet material, or upstream patch knowledge were used.
