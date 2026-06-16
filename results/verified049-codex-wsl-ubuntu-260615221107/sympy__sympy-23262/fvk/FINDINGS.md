# Findings

Status: constructed, not machine-checked.

## F-001: Native Singleton Tuple Was the Defect and V1 Fixes It

Input: `lambdify([], tuple([1]))`

Observed pre-fix behavior from the public issue: generated source contained `return (1)`, so the function returned integer `1`.

Expected behavior from public intent: generated source must contain `return (1,)`, so the function returns a one-element tuple.

Cause: `_recursive_to_string` manually formatted native tuples as `"(" + joined_elements + ")"`. With one element, that is Python grouping syntax rather than tuple syntax.

V1 status: resolved. The tuple branch now handles `len(arg) == 1` with `(<recursive element>,)`. This discharges PO-2 and PO-5.

## F-002: Frame Conditions Remain Satisfied

Input classes: empty tuple, tuples with two or more elements, native lists, and nested elements.

Expected behavior: preserve existing valid source forms and recursive element order.

V1 status: no problem found. V1 only returns early for native tuples of length one. The existing shared formatting path remains active for lists, empty tuples, and tuples of length at least two. This discharges PO-3 and PO-4.

## F-003: No Compatibility Break Found

Input class: public callers of `lambdify`, `lambdastr`, and internal callers of `_recursive_to_string`.

Expected behavior: no signature or protocol change.

V1 status: no problem found. `_recursive_to_string` still takes `(doprint, arg)` and returns a string. `_EvaluatorPrinter.doprint` and `lambdastr` still consume a string expression fragment. This discharges PO-6.

## F-004: Residual Out-of-Domain Case

Input class: cyclic Python containers or arbitrary iterable types other than list and tuple.

Observed from source: `_recursive_to_string` recursively traverses list/tuple containers and raises `NotImplementedError` for unsupported iterable types.

Expected from public intent: not specified by this issue. The issue concerns native Python tuple expression output in `lambdify`.

Status: not a code-change finding for this task. The FVK domain is finite, acyclic list/tuple expression trees; cyclic containers and arbitrary iterables remain outside the proven contract.

## Proof-Derived Findings

No additional source defect was found by the constructed proof obligations. The proof is not machine-checked; running the emitted `kompile` and `kprove` commands remains required before using the proof for test-removal decisions.

