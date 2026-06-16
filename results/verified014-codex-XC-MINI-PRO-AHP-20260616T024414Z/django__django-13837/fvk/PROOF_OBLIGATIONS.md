# Proof Obligations

Status: constructed obligations; not machine-checked.

## O1: Package Parent Branch

Precondition: `__main__.__spec__.parent == P` for non-empty string `P`.

Postcondition: `get_child_arguments()` returns
`[sys.executable] + warning_args + ["-m", P] + sys.argv[1:]`.

Evidence: E1, E2, E4.

K claim: `PACKAGE_MAIN`.

Status: discharged by source inspection and one-step branch proof.

## O2: Existing Script Branch

Precondition: no non-empty parent; `Path(sys.argv[0]).exists()` is true.

Postcondition: return `[sys.executable] + warning_args + sys.argv`.

Evidence: E5, E6.

K claim: `SCRIPT_EXISTS`.

Status: discharged by source inspection and one-step branch proof.

## O3: Missing Script Fallback Ordering

Precondition: no non-empty parent; `Path(sys.argv[0]).exists()` is false.

Postcondition: preserve existing fallback order: `.exe` direct entrypoint,
then `-script.py` entrypoint through Python, then missing-script RuntimeError.

Evidence: E6.

K claims: `EXE_FALLBACK`, `SCRIPT_FALLBACK`, `MISSING_SCRIPT`.

Status: discharged by source inspection and branch proof; unchanged from V1's
surrounding code.

## O4: No `__file__` Dependency for Package Detection

Precondition: package parent branch O1.

Postcondition: the decision depends on `__main__.__spec__.parent`, not on
`django.__main__.__file__` or a `sys.argv[0]` path comparison.

Evidence: E3, E4.

K coverage: represented by `PACKAGE_MAIN`, whose inputs do not include a
Django path. Source-inspection coverage confirms the import/path comparison was
removed.

Status: discharged.

## O5: Warning Option Preservation

Precondition: any returning branch except `.exe` direct fallback.

Postcondition: each warning option `w` appears as `-Ww` immediately after
`sys.executable`.

Evidence: E6 and existing implementation contract.

K coverage: `warnArgs()` helper in `mini-autoreload.k`.

Status: discharged for modeled returning branches.

## O6: Restart Consumer Compatibility

Precondition: `restart_with_reloader()` calls `get_child_arguments()`.

Postcondition: no caller signature, return type, or subprocess invocation shape
changes are required.

Evidence: source inspection of `restart_with_reloader()`.

K coverage: compatibility audit, not a separate reachability claim.

Status: discharged by `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

## O7: Termination

Precondition: call to `get_child_arguments()`.

Postcondition: finite branch execution; no loops in the audited function.

Evidence: source inspection.

K coverage: all claims rewrite directly to `returned(...)` or
`runtimeError(...)`.

Status: discharged for partial correctness. No total proof was machine-checked.
