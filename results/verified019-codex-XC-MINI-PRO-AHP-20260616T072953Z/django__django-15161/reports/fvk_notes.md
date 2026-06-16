# FVK Notes

## Decision

V1 stands unchanged. The FVK audit confirmed that the existing source patch
matches the public intent for this issue: exact instances of root-exported,
deconstructible expression classes should return `django.db.models.<ClassName>`
from `deconstruct()`.

## Trace to Findings and Proof Obligations

FINDING F-001 and PO-1/PO-2 justify keeping the V1 decorators on
`Expression`, `OuterRef`, `Func`, `Value`, `ExpressionList`,
`ExpressionWrapper`, `When`, `Case`, `OrderBy`, `Window`, `WindowFrame`,
`RowRange`, and `ValueRange`. These are the comparable expression classes that
are exported from `django.db.models` and already participate in expression
deconstruction.

FINDING F-002 and PO-3/PO-4 justify keeping the implementation style as
decorator metadata instead of changing `django.utils.deconstruct.deconstructible`
or migration serialization globally. The exact-type guard preserves subclass
and internal-helper fallback behavior, while constructor args and kwargs remain
unchanged.

FINDING F-003 and PO-6 justify not adding decorators to `Subquery` or `Exists`.
They are root-exported expression classes, but in this codebase they do not
currently define or inherit `deconstruct()`. Adding such support would create a
new serialization contract for query-bearing expressions, which the public
issue does not require.

FINDING F-004 and PO-1/PO-8 classify legacy long-path expectations as suspect
where they conflict with the issue. This supports the code change despite
preexisting expectations that may have encoded the bug.

FINDING F-005 and PO-8 record the verification boundary: no tests, Python, or K
tooling were run. The proof is constructed only, so no test removal or
machine-verified confidence is claimed.

## Changes Made in the FVK Phase

No source files under `repo/` were changed in the FVK phase.

Added the required FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Also added companion FVK adequacy and formal-core artifacts required by the FVK
method documentation:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python-deconstruct.k`
- `fvk/deconstructible-expressions-spec.k`
