# Constructed Proof

Status: constructed, not machine-checked. Per task instructions, no `kompile`,
`kast`, `kprove`, Python, or tests were executed.

## Machine-Check Commands Not Run

From the workspace root, a later machine-checking pass would run:

```sh
kompile fvk/mini-autoreload.k --backend haskell
kast --backend haskell fvk/get-child-arguments-spec.k
kprove fvk/get-child-arguments-spec.k
```

Expected machine-check result if the fragment and claims are accepted:
`kprove` returns `#Top` for all claims. This expectation is not asserted as a
machine-checked fact in this artifact.

## Proof Summary

The audited function has no loops. Each proof obligation is a branch proof over
the finite decision tree in `get_child_arguments()`.

The source computes:

1. `main_spec = getattr(sys.modules["__main__"], "__spec__", None)`
2. `package = getattr(main_spec, "parent", None)`
3. `args = [sys.executable] + ["-W%s" % option for option in sys.warnoptions]`
4. branch on `if package`, then on path/fallback existence.

## PACKAGE_MAIN

Assume `package == P` and `P` is non-empty. The first branch is taken before
any `Path(sys.argv[0]).exists()` fallback. The code appends `["-m", P]` and
then `sys.argv[1:]` to the Python/warning prefix. This reaches exactly the
post-state in claim `PACKAGE_MAIN`.

This proves O1 and O4 for the modeled domain: the branch uses the spec parent
value and has no dependency on `django.__main__.__file__`.

## SCRIPT_EXISTS

Assume there is no non-empty package parent and `Path(sys.argv[0]).exists()` is
true. The package branch is skipped and the missing-path fallback branch is
skipped. The final `else` appends all of `sys.argv` to the Python/warning
prefix. This reaches claim `SCRIPT_EXISTS`.

This proves O2 for existing scripts, directories, and zip path entries as
modeled by the existing-path boolean.

## EXE_FALLBACK

Assume no non-empty package parent, missing `sys.argv[0]`, and existing `.exe`
fallback. The code enters `elif not py_script.exists()`, finds
`exe_entrypoint.exists()`, and returns `[str(exe_entrypoint), *sys.argv[1:]]`.
This reaches claim `EXE_FALLBACK`.

This proves the first fallback part of O3.

## SCRIPT_FALLBACK

Assume no non-empty package parent, missing `sys.argv[0]`, no `.exe` fallback,
and existing `-script.py` fallback. The code skips the `.exe` return, finds the
script fallback, and returns the Python/warning prefix plus the fallback script
and `sys.argv[1:]`. This reaches claim `SCRIPT_FALLBACK`.

This proves the second fallback part of O3 and warning preservation O5 for this
branch.

## MISSING_SCRIPT

Assume no non-empty package parent, missing `sys.argv[0]`, and no fallback
entrypoints. The code reaches the final raise in the fallback block:
`RuntimeError("Script %s does not exist." % py_script)`. The model represents
that observable as `runtimeError("Script " + head(argv) + " does not exist.")`,
which is claim `MISSING_SCRIPT`.

This proves the error branch of O3.

## Adequacy and Compatibility

`fvk/SPEC_AUDIT.md` maps every formal-English claim back to public intent.
No claim is implementation-only except the frame conditions that preserve
pre-existing fallback behavior and are supported by public tests.

`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` records that the changed symbol's signature
and return shape are unchanged, and the only direct production caller,
`restart_with_reloader()`, still consumes the returned list without adaptation.

## Test Recommendation

No test removal is recommended. The proof is constructed but not
machine-checked, and the benchmark explicitly forbids modifying tests. Tests
for warning options and fallback behavior remain valuable compatibility checks.
Any path-only `python -m django` test should be treated as suspect mechanism
evidence if maintainers revise the public test suite, because the issue asks
for spec-parent detection rather than `__file__` detection.

## Residual Risk

The proof is partial correctness over a small abstraction of Python path and
module-spec behavior. It relies on the issue's public statement of Python's
`__main__.__spec__.parent` semantics and on the mini-K model faithfully
representing the branch structure. It is constructed, not machine-checked.
