# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

Keep V1 unchanged.

## Rationale

F-001 and F-002 are the only source-code defects or corner-case obligations surfaced by the audit, and V1 discharges them through PO-1, PO-2, PO-3, PO-5, and PO-7.

F-003 is a proof capability limitation caused by the task constraints and the mini-semantics boundary. It does not identify a source branch that violates public intent.

F-004 confirms the frame condition: no public evidence asks for non-mpmath printer changes.

## Recommended Future Checks

When an execution environment exists, add or run public tests equivalent to:

- `lambdify(x, S(1)/3, 'mpmath')` source contains `mpf(1)/mpf(3)` or the fully-qualified equivalent.
- `lambdify(x, -S(1)/3, 'mpmath')` source contains a negative mpmath-wrapped rational.
- The original `nsolve` scenario evaluates the rational target at the requested precision.

When K tooling exists, run:

```sh
cd fvk
kompile mini-python-printer.k --backend haskell
kast --backend haskell mpmath-rational-printer-spec.k
kprove mpmath-rational-printer-spec.k
```

Do not remove tests solely based on this constructed proof.
