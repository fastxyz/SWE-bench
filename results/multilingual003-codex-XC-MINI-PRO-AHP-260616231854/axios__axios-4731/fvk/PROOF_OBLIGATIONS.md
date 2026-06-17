# FVK Proof Obligations

Status: constructed, not machine-checked. Commands are listed in `fvk/PROOF.md` and were not executed.

## PO-001: Default unlimited value reaches follow-redirects as Infinity

- Claim: C1 `compute(finite(-1), false, false) -> res(follow, inf)`.
- Proven slice: `config.transport` absent, `config.maxRedirects !== 0`, `config.maxBodyLength === -1`.
- Source condition in V2: `config.maxBodyLength > -1` is false; `!config.transport && config.maxRedirects !== 0` is true; assign `Infinity`.
- Finding trace: F-001.

## PO-002: The unlimited follow family is covered, not only the single default example

- Claim: C2 `not gtMinusOne(finite(N))` and follow transport implies downstream `inf`.
- Covered values: `finite(-1)` and other finite values not greater than `-1`, matching the adapter's existing `> -1` sentinel convention.
- Source condition in V2: same branch as PO-001.
- Finding trace: F-001.

## PO-003: Native no-redirect unlimited behavior remains compatible

- Claim: C6 `compute(finite(N), false, true) -> res(native, omitted)` when `not gtMinusOne(finite(N))`.
- Source condition in V2: `config.maxRedirects === 0` selects native transport; the new `else if` is false, so no unlimited `maxBodyLength` option is added.
- Finding trace: F-002.

## PO-004: Custom transport unlimited behavior remains compatible

- Claim: C7 `compute(finite(N), true, RD) -> res(custom, omitted)` when `not gtMinusOne(finite(N))`.
- Source condition in V2: `config.transport` selects custom transport; the new `else if` is false because `!config.transport` is false.
- Finding trace: F-002.

## PO-005: Explicit greater-than-`-1` values pass through unchanged

- Claims: C3, C4, C5.
- Covered values: finite values `0` and above, and `Infinity`.
- Source condition in V2: `if (config.maxBodyLength > -1)` assigns the configured value before the unlimited-only branch can run.
- Finding trace: F-003.

## PO-006: Documentation obligation is acknowledged but not discharged by source proof

- Claim status: not encoded as a code claim because it is not production-source behavior.
- Public intent: issue requests documentation of the default.
- Finding trace: F-004.
- Follow-up: update docs/changelog in a documentation-scoped task.

## PO-007: Domain restriction is explicit

- Claim status: domain side condition.
- Domain: legal numeric axios limit values that participate in the `> -1` sentinel convention, plus `Infinity`.
- Excluded values: `NaN`, `null`, non-number coercions, and malformed configs.
- Finding trace: F-005.
