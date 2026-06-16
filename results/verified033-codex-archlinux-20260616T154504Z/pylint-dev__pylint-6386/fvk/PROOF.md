# Constructed Proof

Status: constructed, not machine-checked. No K tooling, Python, or tests were run.

## Machine-Check Commands To Run Later

```sh
kompile fvk/mini-cli.k --backend haskell
kast --backend haskell fvk/cli-verbose-spec.k
kprove fvk/cli-verbose-spec.k
```

Expected machine-check result after installing/running K: `kprove` returns `#Top` for all claims.

## Proof Sketch

The proof uses `fvk/mini-cli.k`, a minimal CLI preprocessing semantics that keeps only the state this issue observes: the remaining argument list, the output argument list, and `Run.verbose`. It also models the verbose option descriptor's `nargs` as `verboseNargs() => 0`.

### C1: SHORT-VERBOSE

Initial state: `<k> preprocess(shortVerbose() ; REST) </k>`, `<verbose> false </verbose>`, with arbitrary output state `OUT`.

Rule used: `preprocess(shortVerbose() ; REST)` rewrites to `preprocess(REST)` and rewrites `<verbose>` to `true`, while `<out>` is framed unchanged. This discharges PO1 and PO2 for the short flag independently of the following arguments.

### C2: SHORT-VERBOSE-AFTER-FILE

Initial state: `<k> preprocess(other("mytest.py") ; shortVerbose() ; .Args) </k>`.

First, the `other(S)` rule appends `other("mytest.py")` to `<out>` and continues with `preprocess(shortVerbose() ; .Args)`. C1's reasoning then sets `<verbose>` to `true`, frames the output, and leaves `preprocess(.Args)`, which rewrites to `done`. This proves the command shape from the issue: file/path arguments are preserved while `-v` enables verbose mode.

### C3: SHORT-VERBOSE-VALUE-ERROR

Initial state: `<k> preprocess(shortVerboseValue("true") ; .Args) </k>`.

The no-value error rule rewrites directly to `error("Option -v doesn't expects a value")` and does not change `<verbose>` or `<out>`. This matches the intended no-argument flag contract and discharges PO3.

### C4: SEPARATOR-FRAME

Initial state: `<k> preprocess(separator() ; shortVerbose() ; REST) </k>`.

The separator rule rewrites directly to `done`, appending `separator() ; shortVerbose() ; REST` to `<out>` and leaving `<verbose>` unchanged. No recursive preprocessing step reaches the following `shortVerbose()`. This proves the V2 separator guard and discharges PO4.

### C5: VERBOSE-NARGS-ZERO

Initial state: `<k> verboseNargs() </k>`.

The descriptor rule rewrites directly to `0`. This models the source fact that the verbose option descriptor now has `kwargs={"nargs": 0}` and discharges PO5. PO6 connects that modeled descriptor value to the actual argparse observable through the existing `_CallableArgument.kwargs` forwarding path.

## Proof-Derived Findings

The V1 audit surfaced F3: after broadening preprocessing from `--`-only to single-dash aliases, a `--` separator frame condition was needed to avoid consuming `-v` after the separator. V2 adds that guard. No additional unresolved proof obstacle remains in the scoped model.

## Test Guidance

Recommended tests to add or keep, without modifying test files in this task:

- `Run([path, "-v"])` or an equivalent CLI test should show no argparse "expected one argument" error and should put startup in verbose mode.
- Help output for verbose should not contain a `VERBOSE` metavar.
- `_preprocess_options` or an end-to-end CLI test for `["--", "-v"]` should confirm `-v` is not consumed as verbose after the separator.

No test removal is recommended from this constructed-only proof. Any future redundancy decision is conditioned on running the recorded K commands and receiving `#Top`.
