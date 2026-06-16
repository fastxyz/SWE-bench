# FVK Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Claims Proved In The Model

P-001: `CAPFD-PRESERVES-CR` proves that text fd capture returns `"Greetings from DOS\r"` unchanged when that is the captured text content.

P-002: `CAPFD-PRESERVES-STDERR-CR` proves the same for stderr content `"  0%\r"`.

P-003: `CAPFDBINARY-PRESERVES-BYTES` proves that byte fd capture returns raw bytes unchanged.

## Constructed Proof Sketch

For P-001, source inspection discharges PO-001 and establishes that V1 constructs the fd-capture text wrapper with `newline=""`. The formal initial state places `bytes("Greetings from DOS\r")` in `<tmp>` and `Preserve` in `<newline>`.

The `snapText` rule in `fvk/mini-capture.k` rewrites the command to `.K`, consumes the temporary bytes by rewriting `<tmp>` to `.Bytes`, and writes `decodePreserve(bytes("Greetings from DOS\r"))` into `<textResult>`.

The `decodePreserve` function rewrites directly to the same text string. Therefore the final `<textResult>` is `"Greetings from DOS\r"`, satisfying the postcondition and the issue reproducer's `out.endswith("\r")` obligation.

For P-002, the same proof applies with the concrete captured text `"  0%\r"`. PO-004 establishes that stderr uses the same `FDCapture` path as stdout, so there is no separate stderr mechanism that could still normalize `"\r"`.

For P-003, the `snapBytes` rule reads the `<tmp>` bytes directly into `<bytesResult>` and empties `<tmp>`. It does not invoke `decodeTranslate` or `decodePreserve`, matching `FDCaptureBinary.snap()` reading `self.tmpfile.buffer.read()`. Therefore undecodable bytes and newline bytes remain byte-exact.

There are no loop obligations and no termination proof obligations in this target; the audited operations are straight-line snapshot operations.

## Adequacy Gate

The English meaning of P-001 and P-002 matches intent entries I-001 through I-003: fd text capture returns text and preserves carriage returns.

The English meaning of P-003 matches intent entry I-004: binary fd capture returns bytes unchanged.

The compatibility frame condition matches I-005: V1 changes only an internal text-wrapper configuration argument and does not alter public APIs.

No formal claim depends on the legacy buggy output `"\n"` as expected behavior.

## Residual Risk

The proof relies on a mini semantics of the relevant capture path, not a full Python or pytest semantics.

The proof is partial correctness for the snapshot operation. It does not prove process-level scheduling, subprocess execution, filesystem behavior, or all `io.TextIOWrapper` internals.

The proof is constructed only. A real machine check may require ordinary K syntax adjustments to the intentionally small mini semantics before running `kprove`.

## Commands Not Run

```sh
kompile fvk/mini-capture.k --backend haskell
kast --backend haskell fvk/capture-spec.k
kprove fvk/capture-spec.k
```

Expected result after any necessary syntax adjustments for the local K version: `kprove` returns `#Top` for the three claims.

## Test Recommendation

Do not remove any tests based on this constructed proof. After machine-checking, a focused unit test for the exact `capfd` carriage-return reproducer would be subsumed by P-001, but it should remain in the suite as a regression test unless maintainers explicitly choose otherwise.
