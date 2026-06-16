# FVK Spec for django__django-13837

Status: constructed, not machine-checked. No tests, Python snippets, or K tools
were executed.

## Unit Under Audit

`repo/django/utils/autoreload.py::get_child_arguments()`

This function builds the command-line argument vector used by
`restart_with_reloader()` when Django's autoreloader starts a child process.
The audited code has finite branch structure and no loops.

## Intent Ledger

Critical entries are mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md` and as
`SPEC-PROVENANCE` comments in `fvk/get-child-arguments-spec.k`.

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt / issue | "Allow autoreloading of `python -m pkg_other_than_django runserver`" | Preserve `python -m P` for package `P`. | Encoded in O1 / `PACKAGE_MAIN`. |
| E2 | prompt / issue | "detects only when -m was passed specifically django" | Do not hard-code `django`. | Encoded in O1/O4. |
| E3 | prompt / issue | "`__file__` is not true of all Python environments" | Do not depend on entry module `__file__`. | Encoded in O4. |
| E4 | prompt / issue | "`__main__.__spec__.parent == \"pkg\"`" | Use non-empty spec parent as the package name. | Encoded in O1. |
| E5 | prompt / issue | directory/zip execution has empty parent | Empty parent is not a package `-m` branch. | Encoded in O2/O3. |
| E6 | public tests | warnoptions and Windows fallbacks | Preserve non-package branch behavior. | Encoded in O2/O3. |
| E7 | public tests | path-only `django.__main__.__file__` simulation | Suspect as mechanism; useful only for preserving real `-m django`. | Recorded in `FINDINGS.md`. |

## Formal Domain

The spec models `get_child_arguments()` over:

- `sys.executable` as a string;
- `sys.warnoptions` as a list of strings;
- non-empty `sys.argv` as a list of strings;
- `__main__.__spec__.parent` as either `parent(P)` for non-empty package name
  `P`, or `noParent()` for missing/empty parent;
- path-existence booleans for `Path(sys.argv[0]).exists()`, `.exe` fallback,
  and `-script.py` fallback.

This abstraction keeps the observable property under verification: the exact
shape and ordering of the returned child argument list.

## Branch Contracts

O1. If parent is non-empty package `P`, return:

`[sys.executable] + ["-W" + option for option in sys.warnoptions] + ["-m", P] + sys.argv[1:]`

O2. If parent is missing/empty and `sys.argv[0]` exists, return:

`[sys.executable] + ["-W" + option for option in sys.warnoptions] + sys.argv`

O3. If parent is missing/empty and `sys.argv[0]` is missing, preserve the
existing ordered fallback behavior: `.exe` fallback first, then `-script.py`,
then `RuntimeError`.

O4. The package branch has no dependency on `django.__main__.__file__` or any
entry module `__file__`.

O5. `restart_with_reloader()` remains compatible because it calls
`get_child_arguments()` without parameters and consumes the same list shape.

## Formal Files

- `fvk/mini-autoreload.k`: minimal K fragment for the branch structure and list
  construction.
- `fvk/get-child-arguments-spec.k`: reachability claims for O1-O3.

Exact machine-check commands are recorded in `fvk/PROOF.md`; they were not run.
