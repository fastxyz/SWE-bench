# Public Evidence Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "annoying `.pylint.d` directory in my home folder" | Do not default to `~/.pylint.d` for normal homes. |
| E2 | `benchmark/PROBLEM.md` | XDG directories include cache and data locations | Use an XDG-style program directory. |
| E3 | `benchmark/PROBLEM.md` hints | "`PYLINTHOME` can be set to the directory of your choice" | Preserve exact override behavior. |
| E4 | `benchmark/PROBLEM.md` hints | old default was `~/.pylint.d` or current `.pylint.d` | Treat home fallback as buggy, retain no-home fallback. |
| E5 | `benchmark/PROBLEM.md` hints | stats are "not crucial" and may belong in `~/.cache` | Prefer XDG cache over XDG data. |
| E6 | `repo/pylint/config/__init__.py` | stats pickle load/save under `PYLINT_HOME` | Preserve stats path construction under the selected directory. |
| E7 | `repo/doc/faq.rst` | FAQ documents persistent-data location | Keep public docs consistent with behavior. |

