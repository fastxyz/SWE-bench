# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Quoted evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "The short option of the `verbose` option expects an argument." | `-v` is in scope and current value-taking behavior is the bug. | Encoded by PO1, PO2, C1, C2. |
| E2 | `benchmark/PROBLEM.md` | "The long option works ok & doesn't expect an argument: `pylint mytest.py --verbose`" | `-v` must match the no-value flag behavior of `--verbose`. | Encoded by PO1, PO3, C1, C3. |
| E3 | `benchmark/PROBLEM.md` | "help message for the `verbose` option suggests a value `VERBOSE` should be provided." | Verbose option metadata must be zero-argument metadata. | Encoded by PO5, PO6, C5. |
| E4 | `repo/doc/technical_reference/startup.rst` | "`Run` ... basic checking of the given command line options ... when preprocessing the command line options." | `_preprocess_options` is the relevant early preprocessing unit. | Used to scope SPEC and proof. |
| E5 | `repo/pylint/__init__.py` | "`argv` can be a sequence of strings normally supplied as arguments on the command line" | Default command-line argument conventions apply unless contradicted. | Encodes `--` separator frame in PO4, C4. |
| E6 | `repo/pylint/config/utils.py` | `PREPROCESSABLE_OPTIONS` maps options to `(takearg, callback)` and `_set_verbose_mode` asserts `value is None`. | Verbose preprocessing must call `_set_verbose_mode` with no value. | Used in proof semantics. |
| E7 | `repo/pylint/config/arguments_manager.py` | `_CallableArgument` kwargs are passed into `section_group.add_argument(...)`. | `{"nargs": 0}` on `verbose` reaches argparse. | Encoded by PO6. |

SUSPECT legacy evidence: the reported Pylint output `argument --verbose/-v: expected one argument` is explicitly the buggy behavior, so it is not a preservation obligation.
