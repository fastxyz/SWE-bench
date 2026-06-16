# Public Evidence Ledger

| ID | Source | Quote or source fact | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "Require a non-empty name for Blueprints" | Empty string is invalid for blueprint names. |
| E1b | `benchmark/PROBLEM.md` | "It would be helpful if a `ValueError` was raised" | Invalid empty-name attempts raise `ValueError`. |
| E2 | `repo/docs/blueprints.rst` | The blueprint name prefixes endpoint names. | Name is a namespace component; empty names are semantically meaningful breakage. |
| E3 | `repo/docs/blueprints.rst` | Endpoints are prefixed by blueprint name and separated by dot. | Valid names must preserve endpoint prefixing behavior. |
| E4 | `repo/CHANGES.rst` | Dot separates nested blueprint names and endpoint names. | Existing dotted constructor-name guard remains. |
| E5 | `repo/CHANGES.rst` | `register_blueprint` takes `name=` to change the pre-dotted name. | Registration override `name=""` is an empty effective blueprint name. |
| E6 | `repo/src/flask/blueprints.py` | `self_name = options.get("name", self.name)` | Implementation point where registration override becomes effective. |

