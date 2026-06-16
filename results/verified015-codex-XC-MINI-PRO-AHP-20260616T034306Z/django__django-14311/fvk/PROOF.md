# Constructed Proof

Status: constructed, not machine-checked. The commands below were recorded but
not executed.

## Machine-Check Commands

```sh
cd fvk
kompile mini-python-argv.k --backend haskell
kast --backend haskell get-child-arguments-spec.k
kprove get-child-arguments-spec.k
```

Expected machine-check result after running the commands in an environment with
K installed: `#Top` for all claims.

## Claims Proved

The proof constructs the following all-path reachability claims:

- `MODULE-SPEC-FULL-NAME`: ordinary `python -m` module specs return
  `BASE + ["-m", NAME] + TAIL`.
- `PACKAGE-MAIN-USES-PARENT`: exact `__main__` and `.__main__` package specs
  return `BASE + ["-m", PARENT] + TAIL`.
- `EMPTY-SPEC-SCRIPT-FALLBACK`: empty module-name specs fall through to script
  fallback.
- `NO-SPEC-SCRIPT-FALLBACK`: absent specs with an existing script path return
  `BASE + FULL`.
- `EXE-FALLBACK`: absent specs with an `.exe` fallback return `[EXE] + TAIL`.
- `EMPTY-SPEC-EXE-FALLBACK`: the same `.exe` result holds when a present spec
  yields no usable module name.
- `SCRIPT-ENTRY-FALLBACK`: absent specs with a `-script.py` fallback return
  `BASE + [SCRIPT] + TAIL`.
- `EMPTY-SPEC-SCRIPT-ENTRY-FALLBACK`: the same `-script.py` result holds when a
  present spec yields no usable module name.
- `MISSING-SCRIPT-ERROR`: absent specs with no fallback raise the missing-script
  RuntimeError.
- `EMPTY-SPEC-MISSING-SCRIPT-ERROR`: the same RuntimeError result holds when a
  present spec yields no usable module name.

## Adequacy Gate

The formal-English paraphrases in `fvk/FORMAL_SPEC_ENGLISH.md` were compared
against `fvk/INTENT_SPEC.md` in `fvk/SPEC_AUDIT.md`.

Result: pass. No formal claim is weaker than the public issue intent, and no
claim over-preserves the pre-V1 bug.

## Symbolic Proof Sketch

`get_child_arguments()` initializes:

- `BASE = [sys.executable] + warn-argument list`
- `TAIL = sys.argv[1:]`
- `FULL = sys.argv`

Then the proof case-splits on the abstract `Spec`.

### Case 1: `moduleSpec(NAME)`

The predicate "exact `__main__` or suffix `.__main__`" is false by the
`moduleSpec` classifier. V1 executes the `else` branch at line 230 and assigns
`module_name = spec.name` at line 231. Since `NAME` is non-empty, line 232 is
true, lines 233 and 234 append `["-m", NAME]` and `TAIL`, and line 235 returns.

This discharges PO1, including `foo.bar.baz`, `custom_module`, and
`foo.my__main__`.

### Case 2: `packageMainSpec(PARENT)`

The package-main predicate is true. V1 assigns `module_name = spec.parent` at
line 229. Since `PARENT` is non-empty, the same return path at lines 232 through
235 returns `BASE + ["-m", PARENT] + TAIL`.

This discharges PO2 and preserves `python -m django`.

### Case 3: `emptyMainSpec`

The spec branch computes an empty module name. The guard at line 232 is false,
so control does not return from the `__spec__` block. The proof then continues
through the same path-fallback split as Case 4.

This discharges PO3 when `PathState = scriptExists` and participates in PO5
through PO7 for missing script paths.

### Case 4: `noSpec`

There is no `__spec__`, so the proof skips directly to the path-fallback split.

If `py_script.exists()` is true, line 249 appends `FULL` to `BASE` and line 250
returns. This discharges PO4.

If `py_script.exists()` is false and the `.exe` entry point exists, lines 239
through 242 return `[EXE] + TAIL`. This discharges PO5.

If the `.exe` entry point does not exist and the `-script.py` entry point
exists, lines 243 through 246 return `BASE + [SCRIPT] + TAIL`. This discharges
PO6.

If neither fallback exists, line 247 raises the missing-script RuntimeError.
This discharges PO7.

## Termination

The audited function has no loop or recursion. The constructed proof covers a
finite decision tree. No separate total-correctness measure is needed for this
helper.

## Test-Redundancy Recommendation

Recommendation only, conditioned on machine-checking. Do not delete tests in
this benchmark.

The constructed proof subsumes the in-domain point assertions covered by the
existing child-argument tests for package `__main__`, no-spec script execution,
warn options, `.exe` fallback, `-script.py` fallback, and missing-script error.
Integration tests of the reloader process should be kept because the proof is
only for argument reconstruction.

Additional public tests recommended for future maintainers are listed in
`fvk/ITERATION_GUIDANCE.md`; they should be added by maintainers outside this
benchmark constraint, not by this run.

## Residual Risk

The trusted base is the adequacy of the mini argument-reconstruction semantics,
the correctness of the classifier abstraction for CPython `__spec__` states, and
the K/reachability prover once the recorded commands are run. Because no K
tooling was executed, this is a constructed proof, not a machine-checked proof.
