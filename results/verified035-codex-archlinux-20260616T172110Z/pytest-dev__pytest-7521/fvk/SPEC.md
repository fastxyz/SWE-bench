# FVK Specification

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

This FVK pass audits the V1 fix for the observable path in the issue:

`capfd` fixture -> `CaptureFixture.readouterr()` -> `MultiCapture.readouterr()` -> `FDCapture.snap()` -> `EncodedFile.read()`.

The proof model also includes the frame condition for the shared binary path:

`capfdbinary` fixture -> `FDCaptureBinary.snap()` -> `EncodedFile.buffer.read()`.

There are no loops in the audited path, so there are no loop circularities.

## Intent Spec

I-001: Text fd capture must preserve a carriage return written by captured code. The issue's reproducer writes `end="\r"` and asserts that `capfd.readouterr().out` ends with `"\r"`.

I-002: Text fd capture applies to both stdout and stderr. The reported borgbackup failure expected stderr to equal `"  0%\r"`.

I-003: `capfd.readouterr()` returns text objects, not bytes.

I-004: `capfdbinary.readouterr()` returns bytes and must continue preserving raw bytes.

I-005: The fix must not change public fixture names, signatures, return shape, or the capture start/suspend/resume protocol.

## Public Evidence Ledger

E-001, prompt: "capfd.readouterr() converts \r to \n" is reported as the bug. Obligation: do not normalize lone carriage returns in text fd capture. Status: encoded by PO-001 and claim `CAPFD-PRESERVES-CR`.

E-002, prompt reproducer: `print('Greetings from DOS', end='\r')` followed by `assert out.endswith('\r')`. Obligation: captured stdout text ends with `\r`. Status: encoded by PO-003.

E-003, prompt borgbackup failure: `assert err == '  0%\r'`. Obligation: captured stderr text preserves `\r`. Status: encoded by PO-004.

E-004, prompt comparison: pytest 5 passed and pytest 6.0.0rc1 failed. Obligation: this is a regression, so preserve the previous externally observable behavior. Status: encoded by PO-001 through PO-004.

E-005, docs: `capfd` enables text capturing of writes to file descriptors `1` and `2`, returning text objects. Obligation: the fix belongs on text fd capture and must keep text return type. Status: encoded by PO-002 and PO-006.

E-006, docs/tests: `capfdbinary` returns bytes, including undecodable bytes. Obligation: byte capture remains byte-exact. Status: encoded by PO-005.

E-007, implementation: `CaptureIO` already constructs `io.TextIOWrapper(..., newline="", write_through=True)`. Obligation: using `newline=""` is consistent with existing sys-capture newline preservation. Status: supports PO-002.

## Formal Spec English

Claim `CAPFD-PRESERVES-CR`: for any fd-captured text bytes equal to `"Greetings from DOS\r"`, `FDCapture.snap()` with `newline=""; read()` returns `"Greetings from DOS\r"` and clears the temporary capture buffer.

Claim `CAPFD-PRESERVES-STDERR-CR`: the same preservation property holds for stderr content such as `"  0%\r"` because stdout and stderr are both represented by `FDCapture`.

Claim `CAPFDBINARY-PRESERVES-BYTES`: for fd-captured bytes such as `b"\xfe\x98 "`, `FDCaptureBinary.snap()` returns those same bytes and clears the temporary capture buffer.

Frame condition: public fixture APIs and `CaptureFixture.readouterr()` aggregation behavior are unchanged; only the internal `EncodedFile` newline mode changes.

## Adequacy Audit

A-001: `CAPFD-PRESERVES-CR` matches I-001 and I-003. Pass.

A-002: `CAPFD-PRESERVES-STDERR-CR` matches I-002. Pass.

A-003: `CAPFDBINARY-PRESERVES-BYTES` matches I-004. Pass.

A-004: The frame condition matches I-005. Pass.

A-005: The spec does not claim termination, scheduling, subprocess behavior beyond fd bytes already written to the capture file, or complete `io.TextIOWrapper` semantics. These are outside this targeted audit. Pass with residual risk recorded in `fvk/FINDINGS.md` F-004.

## Public Compatibility Audit

C-001: `capfd`, `capfdbinary`, `FDCapture`, `FDCaptureBinary`, `CaptureFixture.readouterr()`, and `EncodedFile` public signatures are unchanged. Pass.

C-002: The changed argument is internal to `FDCaptureBinary.__init__` when constructing an `EncodedFile`. No public caller must pass a new argument. Pass.

C-003: Public docs require text for `capfd` and bytes for `capfdbinary`; the V1 fix preserves those return types. Pass.

## Formal Core

The K-style formal core is in:

- `fvk/mini-capture.k`
- `fvk/capture-spec.k`

Exact commands to machine-check later, not run here:

```sh
kompile fvk/mini-capture.k --backend haskell
kast --backend haskell fvk/capture-spec.k
kprove fvk/capture-spec.k
```
