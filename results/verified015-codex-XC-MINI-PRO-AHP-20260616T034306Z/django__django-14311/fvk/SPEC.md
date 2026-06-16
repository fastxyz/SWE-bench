# FVK Specification: django__django-14311

Status: constructed, not machine-checked. No tests, Python, or K tooling were
executed.

## Scope

The audited unit is `django.utils.autoreload.get_child_arguments()` in
`repo/django/utils/autoreload.py`. The observable under verification is the
argument list returned to `restart_with_reloader()`.

There are no loops in the audited function. The proof is a total case split over
the finite branches in `get_child_arguments()`, with partial-correctness wording
retained because the FVK proof was not machine-checked.

## Public Intent Ledger

| ID | Source | Public evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Allow autoreloading of `python -m custom_module runserver`" | A run started with `python -m <module>` must restart through `-m <same module>` and preserve the command tail. | Encoded in PO1. |
| E2 | prompt | "When a dotted name for a module ... `foo.bar.baz` ... the resulting arguments end up being `-m foo.bar`, which is uncalled for." | For ordinary module specs, use `__spec__.name`, not `__spec__.parent`. | Encoded in PO1. |
| E3 | public hint | "change ... to `modspec.name == \"__main__\"` or `modspec.name.endswith(\".__main__\")` ... avoid ... `foo.my__main__`" | Only exact `__main__` or dotted `.__main__` package entry points use the parent; a module merely ending in `my__main__` keeps its full name. | Encoded in PO1 and PO2. |
| E4 | public tests | Existing tests expect `python -m django` and a package `__main__` fixture to restart with the package name. | Preserve package `__main__` behavior. | Encoded in PO2. |
| E5 | public tests | Existing tests cover warn options, `.exe` fallback, `-script.py` fallback, missing script error, and no-spec script execution. | Preserve non-`-m` fallback behavior and warning options. | Encoded in PO3 through PO7. |
| E6 | code comment | "`__spec__` is set when the server was started with the `-m` option" and may not exist. | The `__spec__` branch is the mechanism for `python -m`; absent/empty spec must not bypass existing path fallback. | Encoded in PO1 through PO4. |
| E7 | implementation/API | `restart_with_reloader()` calls `get_child_arguments()` without arguments and passes the returned list to `subprocess.run()`. | The fix must not change the public signature or return shape. | Encoded in PO8. |

## Domain Model

The formal model abstracts CPython and `pathlib` into the state relevant to this
helper:

- `BASE`: `[sys.executable]` plus `['-W%s' % option for option in sys.warnoptions]`.
- `TAIL`: `sys.argv[1:]`.
- `FULL`: `sys.argv`.
- `Spec`: one of `noSpec`, `moduleSpec(NAME)`, `packageMainSpec(PARENT)`, or
  `emptyMainSpec`.
- `PathState`: one of `scriptExists`, `exeEntry(EXE)`, `scriptEntry(SCRIPT)`, or
  `missingScript(ARG0)`.

The classifier represented by `Spec` follows the public intent:

- `packageMainSpec(PARENT)` means `spec.name == "__main__"` or
  `spec.name.endswith(".__main__")`.
- `moduleSpec(NAME)` means all other non-empty module spec names, including
  top-level modules such as `custom_module`, dotted modules such as
  `foo.bar.manage`, and corner-case names such as `foo.my__main__`.
- `emptyMainSpec` means the spec does not yield a truthy module name and must
  fall back to the script-entry behavior.

## Required Behavior

R1. For `moduleSpec(NAME)` with a non-empty `NAME`, return
`BASE + ["-m", NAME] + TAIL`.

R2. For `packageMainSpec(PARENT)` with a non-empty `PARENT`, return
`BASE + ["-m", PARENT] + TAIL`.

R3. For `noSpec` or `emptyMainSpec`, preserve the previous script fallback:
if `sys.argv[0]` exists, return `BASE + FULL`.

R4. If the script path does not exist and an `.exe` entry point exists, return
`[EXE] + TAIL`, ignoring `sys.executable`, as the existing Windows behavior did.

R5. If the script path does not exist and a `-script.py` entry point exists,
return `BASE + [SCRIPT] + TAIL`.

R6. If none of the script fallback paths exists, raise the same missing-script
runtime error.

R7. The function signature, call pattern, and returned command-list shape remain
unchanged.

## Formal Core

The supporting formal files are:

- `fvk/mini-python-argv.k`: a small K semantics for this helper's argument
  reconstruction decision tree.
- `fvk/get-child-arguments-spec.k`: K claims corresponding to PO1 through PO7.

The exact commands to machine-check later are recorded in `fvk/PROOF.md`.

## Adequacy Result

The formal English paraphrases in `fvk/FORMAL_SPEC_ENGLISH.md` match the intent
items above. `fvk/SPEC_AUDIT.md` marks all obligations pass, with no ambiguous
or failed requirement. `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` found no public API or
callsite incompatibility.

## Code Decision

V1 satisfies the specification. No additional production-code edit is justified
by the FVK findings or proof obligations.
