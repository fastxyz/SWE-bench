# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests, Node code, Python, or K tooling were run.

## Machine-Check Commands Not Run

```sh
cd fvk
kompile mini-axios-http-options.k --backend haskell
kast --backend haskell axios-http-options-spec.k
kprove axios-http-options-spec.k
```

Expected machine-check result after tool execution: `#Top` for all claims. Until those commands are run successfully, this is a constructed proof only.

## Semantics Summary

The mini semantics models only the audited adapter slice:

```text
compute(maxBodyLength, hasCustomTransport, redirectsDisabled)
  -> res(selectedTransport, downstreamMaxBodyLength)
```

Rules mirror the V2 source branch order:

1. Custom transport wins when `hasCustomTransport` is true.
2. Native transport wins when no custom transport exists and `redirectsDisabled` is true.
3. Follow transport is selected otherwise.
4. Values greater than `-1` pass through unchanged.
5. Unlimited values on the follow path become `inf`.
6. Unlimited values on native/custom paths remain `omitted`.

## Constructed Proof By Cases

### Follow path, default/unlimited limit

Precondition: `hasCustomTransport = false`, `redirectsDisabled = false`, `MBL = finite(N)`, and `not gtMinusOne(finite(N))`.

Symbolic execution applies the follow/unlimited rule in `mini-axios-http-options.k`, producing `res(follow, inf)`. This discharges PO-001 for `finite(-1)` and PO-002 for the unlimited sentinel family.

Source correspondence: in `repo/lib/adapters/http.js`, the transport falls through to `httpFollow`/`httpsFollow`; `config.maxBodyLength > -1` is false; `!config.transport && config.maxRedirects !== 0` is true; `options.maxBodyLength = Infinity`.

### Native no-redirect path, unlimited limit

Precondition: `hasCustomTransport = false`, `redirectsDisabled = true`, `MBL = finite(N)`, and `not gtMinusOne(finite(N))`.

Symbolic execution applies the native/unlimited rule, producing `res(native, omitted)`. This discharges PO-003 and shows the V2 patch preserves the no-redirect path's unlimited behavior without adding a new option property.

Source correspondence: `config.maxRedirects === 0` selects native `http`/`https`; the V2 `else if (!config.transport && config.maxRedirects !== 0)` guard is false.

### Custom transport path, unlimited limit

Precondition: `hasCustomTransport = true`, `MBL = finite(N)`, and `not gtMinusOne(finite(N))`.

Symbolic execution applies the custom/unlimited rule, producing `res(custom, omitted)`. This discharges PO-004 and resolves the V1 compatibility finding.

Source correspondence: `config.transport` selects the custom transport; the V2 unlimited override guard is false because `!config.transport` is false.

### Explicit configured limit path

Precondition: `gtMinusOne(MBL)`.

Symbolic execution applies one of the greater-than-`-1` rules for the selected transport, producing `res(custom, MBL)`, `res(native, MBL)`, or `res(follow, MBL)`. This discharges PO-005.

Source correspondence: `if (config.maxBodyLength > -1)` runs before the unlimited-only `else if`, so explicit finite limits and `Infinity` are forwarded unchanged.

## Adequacy Result

The claims prove the issue-relevant observable: the value axios gives to the downstream transport is consistent with axios' unlimited sentinel and does not let `follow-redirects` apply its own finite default. The claims also cover the compatibility frame that V1 overreached: native/custom unlimited branches retain the old option omission.

The proof does not discharge the documentation part of the issue and does not claim behavior for malformed numeric values. Those are recorded in `fvk/FINDINGS.md`.

## Test Guidance

Do not delete tests based on this constructed proof. After machine-checking returns `#Top`, unit tests that only assert the covered branch table can be considered redundant, but integration tests around actual `follow-redirects` behavior, stream request bodies, and Node transport wiring should be kept.
