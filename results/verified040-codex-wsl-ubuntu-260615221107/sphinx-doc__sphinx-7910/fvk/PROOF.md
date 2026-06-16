# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
command was executed.

## Machine-check Commands Not Run

```sh
kompile fvk/mini-napoleon.k --backend haskell
kast --backend haskell fvk/napoleon-skip-member-spec.k
kprove fvk/napoleon-skip-member-spec.k
```

Expected machine-check result after syntax/toolchain validation: `#Top` for
the claims C1-C8.

## Proof Sketch

The mini semantics defines `skipMember(WHAT, NAME, HAS_DOC, RESOLVE,
GLOBAL_OWNER, CONFIG)`.

The first rule rewrites to `forceInclude` exactly when all eligibility gates
hold:

- `NAME` is not `weakref`;
- `HAS_DOC` is true;
- `WHAT` is `module`, `class`, or `exception`;
- the relevant include setting in `CONFIG` is true;
- and either `WHAT` is `module`, or `WHAT` is class-like and `ownerFor`
  establishes ownership.

The second rule is `[owise]` and rewrites every remaining state to `default`.

`ownerFor(resolved(OWNER, WRAPPED_OWNER), GLOBAL_OWNER)` rewrites to
`OWNER orBool WRAPPED_OWNER`. This models V2's check of both the resolved class
and `unwrap(cls)`. `ownerFor(unresolvedTop, GLOBAL_OWNER)` rewrites to
`GLOBAL_OWNER`, modeling the top-level compatibility fallback.
`ownerFor(unresolvedDotted, _)` rewrites to `false`, preserving the old behavior
when a dotted path cannot be resolved.

## Claim Discharge

C1 instantiates the first rule with a class init, docstring present, enabled
init config, and `resolved(true, false)`. The side conditions reduce to true,
so the result is `forceInclude`. This discharges PO2.

C2 is the same except `resolved(false, true)`. `ownerFor` reduces to true
because the unwrapped class owns the member. This discharges PO4.

C3 instantiates a private class member with `resolved(true, false)` and private
config enabled. The first rule applies. This discharges PO3.

C4 instantiates unresolved top-level resolution with `GLOBAL_OWNER=true` and
special config enabled. `ownerFor` reduces to true through the fallback. This
discharges PO5.

C5 instantiates no owner candidate. The first rule's ownership condition is
false, so only the `[owise]` rule applies and the result is `default`. This
discharges PO8.

C6 instantiates an owned documented init with init config disabled. The
`includedByConfig` condition is false, so the result is `default`. This
discharges PO6.

C7 instantiates a module private member with private config enabled. Module
members bypass class ownership and the first rule applies. This discharges PO7.

C8 instantiates `weakref`. The first rule is blocked by `NAME =/=K weakref`, so
the result is `default`. This discharges PO1 for the weakref boundary.

## Adequacy And Compatibility

`fvk/SPEC_AUDIT.md` marks every formal-English claim as entailed by the public
intent ledger. `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` finds no public signature,
return-shape, event-dispatch, callsite, or override incompatibility.

## Residual Risk

This proof is partial correctness over an abstract metadata model. It does not
prove termination separately, though the audited source path has no loops. It
does not machine-check syntax or claims because the task forbids running K
tooling. It does not replace integration tests for real Python import,
descriptor, and wrapper behavior.
