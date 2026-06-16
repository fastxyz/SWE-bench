# FVK Notes

Status: constructed, not machine-checked. I did not run tests, Python, or K
tooling.

## Source Decision

V1 stands unchanged.

The decisive finding is F-001, tied to PO-001, PO-004, and PO-005: the public
failure is an escaped `PolynomialError` from the optional `gcd(p, q)` extraction
inside `Mod.eval`. V1 catches exactly `PolynomialError` around that extraction,
sets `G = S.One`, and leaves `p` and `q` unchanged, so the reported path can
continue to symbolic `Mod` construction.

I did not broaden the catch or move it earlier because PO-003 requires preserving
legitimate errors outside the optional extraction block, especially modulo by
zero. The existing zero-divisor guard still executes before the `try` block.

I did not change the successful `gcd` path because F-002 and PO-002 require
existing simplifications to remain available. V1 keeps the original successful
branch inside the `try` block.

## Rejected Alternatives

I did not implement branchwise `gcd` for `Piecewise` expressions. F-003 records
that the public discussion treats this as possible future behavior and notes
that the two-`Piecewise` case is more complicated. That is not required by
PO-001 or PO-005, which are about `Mod` not leaking the optional simplification
failure.

I did not rewrite the old assumptions cache. F-004 records that cache rollback
is broader and would not by itself make the first reported call succeed; without
the `Mod` fix, it would only make the `PolynomialError` deterministic.

## Artifacts

The FVK package under `fvk/` includes the required five artifacts plus the
additional adequacy and K files required by the FVK method docs. The proof is
constructed over a property-complete mini-semantics and remains explicitly not
machine-checked, matching PO-007.
