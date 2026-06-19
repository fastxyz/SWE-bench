# FVK FINDINGS

Status: findings from formalization and constructed proof. No test, Python, or K
tooling was run.

## F-001: Direct one-element tuple lost its cardinality marker

Input shape: `ast.Tuple(elts=[Constant(1)])`, corresponding to source `(1,)`.

Observed in the original implementation: `visit_Tuple()` treated every
non-empty tuple the same way by joining elements and wrapping them in
parentheses, so one element rendered as `(1)`.

Expected from public intent: `(1,)`.

Classification: code bug.

Status: fixed by V1 and retained in V2. `visit_Tuple()` now has an explicit
`len(node.elts) == 1` branch that returns `(<element>,)`.

Proof obligations: PO-1, PO-2.

## F-002: V1 left a sibling one-element tuple formatter incomplete

Input shape: `ast.Subscript(value=Name("obj"), slice=Tuple([Constant(1)]))`,
corresponding to tuple-key subscript syntax such as `obj[1,]`.

Observed in V1 source audit: `visit_Subscript()` had a separate
`is_simple_tuple()` branch that joined tuple slice elements manually. For one
element it would render `obj[1]`, erasing the comma and changing the tuple slice
shape to a scalar slice.

Expected from full intent: `obj[1,]`. The issue's key requirement is preserving
the trailing comma for a one-element tuple; the subscript branch is a separate
contributor to the same observable string returned by `pycode.ast.unparse()`.

Classification: code bug found by FVK completeness audit.

Status: fixed in V2. `visit_Subscript()` now routes simple tuple slices through
`render_simple_tuple()`, which appends a comma when `len(value.elts) == 1` while
preserving the existing multi-element formatting.

Proof obligations: PO-3, PO-4.

## F-003: No public compatibility blocker found

Input/API surface: calls to `sphinx.pycode.ast.unparse()` from autodoc,
type-comment handling, inspection helpers, and parser metadata collection.

Observed in source audit: callers consume a string return value and no call site
depends on a changed signature. The V2 patch changes only rendered output for
tuple cardinality cases that public intent says were wrong or incomplete.

Expected from compatibility intent: no signature, return type, or test-file
change.

Classification: compatibility check.

Status: no code change required beyond the tuple-rendering fixes.

Proof obligations: PO-5.

## F-004: Proof remains constructed, not machine-checked

Input/process shape: the FVK docs request `kompile`, `kast`, and `kprove`
commands, but the benchmark forbids executing K tooling, Python, or tests.

Observed: formal artifacts and expected commands were written, but not run.

Expected process: label proof and test-redundancy statements as constructed,
not machine-checked; do not delete or edit tests.

Classification: proof-process limitation, not a code bug.

Status: honored in `PROOF.md` and `ITERATION_GUIDANCE.md`.

Proof obligations: PO-6.
