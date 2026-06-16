# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "`sphinx-quickstart` with existing conf.py doesn't exit easily" | Existing `conf.py` is the triggering in-domain case. | Encoded in QS-EXISTING-ROOT. |
| E2 | `benchmark/PROBLEM.md` | "Please enter a new root path name (or just Enter to exit)" followed by Enter producing "Please enter a valid path name" | Empty input must not be routed through the normal path validator and loop forever. | Encoded negatively as no replacement prompt on existing-project path. |
| E3 | `benchmark/PROBLEM.md` | "Expected behavior: After pressing Enter, sphinx-quickstart exits." | Existing-project branch must terminate instead of continuing validation. | Encoded as status 1 and no generation. |
| E4 | public hint in `benchmark/PROBLEM.md` | "if the selected path already has a `conf.py`, `sphinx-quickstart` should exit with status 1 immediately" | The preferred repair is immediate status-1 failure for an already-selected project root. | Encoded in QS-EXISTING-ROOT and QS-EXISTING-SOURCE. |
| E5 | `repo/sphinx/cmd/quickstart.py` user-facing warning | "sphinx-quickstart will not overwrite existing Sphinx projects." | Existing projects are rejected before generation. | Supports no-generation postcondition. |
| E6 | `repo/sphinx/cmd/quickstart.py` pre-existing guard | Checks both `<path>/conf.py` and `<path>/source/conf.py`. | Separate-source projects count as existing projects. | Encoded in QS-EXISTING-SOURCE. |
| E7 | `repo/doc/man/sphinx-quickstart.rst` | "sphinx-quickstart is an interactive tool that asks some questions ... and then generates..." | Normal non-conflict interactive flow remains outside the conflicting-path change. | Frame condition only. |
| E8 | public callsite search | `ask_user()` is used internally and by tests; no public override/virtual dispatch is involved. | Public signatures must remain stable. | Checked in compatibility audit. |

## SUSPECT legacy evidence

The replacement-root prompt is legacy behavior quoted as part of the reported
bug. Under the FVK SUSPECT rule, it is evidence of the failure surface, not an
independent obligation to preserve the retry prompt. The public hint supplies a
positive replacement obligation: immediate status-1 exit for the selected path.
