# Iteration Guidance

Status: next-action guidance after FVK audit.

## Code Decision

V1 stands unchanged. Findings F1, F2, and F3 are resolved by the existing V1
normalization calls. Proof obligations PO-1 through PO-8 discharge the code
decision under the constructed proof; PO-9 discharges the no-execution honesty
gate.

## Recommended Source Changes

None.

## Recommended Tests For A Future Test-Enabled Environment

Do not modify tests in this benchmark. In a normal development environment, add
or keep tests for:

- `Header.fromstring` accepts ASCII `bytes` with default separator.
- `Header.fromstring` accepts ASCII `bytes` with `sep=b'\n'`.
- `Card.fromstring` accepts ASCII `bytes`.
- Existing `str` input behavior for both methods.

## Machine Verification

When K tooling is available and execution is permitted, run:

```sh
cd fvk
kompile mini-python-fits.k --backend haskell
kast --backend haskell fits-fromstring-spec.k
kprove fits-fromstring-spec.k
```

Until `kprove` returns `#Top`, keep all tests. The constructed proof justifies
the source reasoning but not test deletion.

## Residual Risks

- The K model abstracts FITS grammar parsing behind `parseHeader` and
  `makeCard`; it proves type-boundary correctness, not full FITS parser
  correctness.
- Exact byte/text equivalence is specified for ASCII bytes. Non-ASCII bytes use
  the existing `decode_ascii` warning/replacement policy.
- No tests, Python code, or K tooling were executed in this benchmark.
