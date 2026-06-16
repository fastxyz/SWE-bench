# Formal Spec in English

Status: paraphrase of the claims in `fvk/get-child-arguments-spec.k`.

## C1: MODULE-SPEC-FULL-NAME

For any non-empty ordinary module spec name `NAME`, including top-level modules,
dotted modules, and names such as `foo.my__main__`, `get_child_arguments()`
returns `BASE + ["-m", NAME] + TAIL`.

## C2: PACKAGE-MAIN-USES-PARENT

For a package `__main__` spec with non-empty parent `PARENT`,
`get_child_arguments()` returns `BASE + ["-m", PARENT] + TAIL`.

## C3: EMPTY-SPEC-SCRIPT-FALLBACK

If a spec exists but produces no usable module name, and the script path exists,
`get_child_arguments()` returns `BASE + FULL`.

## C4: NO-SPEC-SCRIPT-FALLBACK

If no spec exists and the script path exists, `get_child_arguments()` returns
`BASE + FULL`.

## C5: EXE-FALLBACK

If no usable `-m` module name exists, the script path is missing, and the `.exe`
entry point exists, `get_child_arguments()` returns `[EXE] + TAIL`.

## C6: SCRIPT-ENTRY-FALLBACK

If no usable `-m` module name exists, the script path and `.exe` fallback are
missing, and a `-script.py` entry point exists, `get_child_arguments()` returns
`BASE + [SCRIPT] + TAIL`.

## C7: MISSING-SCRIPT-ERROR

If no usable `-m` module name exists and no script fallback exists,
`get_child_arguments()` raises the missing-script RuntimeError.
