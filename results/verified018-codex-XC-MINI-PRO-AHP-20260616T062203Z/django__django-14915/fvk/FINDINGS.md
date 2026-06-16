# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent, source inspection, and constructed proof obligations only.

## F1 - Resolved code bug: wrapper was unhashable

Input: `W = ModelChoiceIteratorValue(1, obj)` and `D = {1: ['first_name', 'last_name']}`.

Pre-V1 observed behavior: `W in D` raised `TypeError: unhashable type: 'ModelChoiceIteratorValue'` because the class defined `__eq__()` without `__hash__()`.

Expected behavior: `W in D` is true and `D[W]` returns `['first_name', 'last_name']`, because `W` compares equal to `1` and must hash like `1`.

Status: resolved by V1's `def __hash__(self): return hash(self.value)`.

Proof obligations: PO2, PO3, PO4, PO5.

## F2 - Confirmed behavior: equality remains value-based

Input: `W = ModelChoiceIteratorValue(1, obj)` and `allowed_values = [1, 2]`.

Observed behavior after V1: the source still uses the existing `__eq__()` implementation, so list membership remains value-based.

Expected behavior: preserve the behavior the issue says already works.

Status: confirmed; no additional source change.

Proof obligations: PO1, PO3.

## F3 - Rejected alternative: replace wrapper with primitive value

Candidate change: make `ModelChoiceIterator.choice()` return `self.field.prepare_value(obj)` directly as the option value.

Predicted result: dictionary membership would work, but user code could no longer access the model instance through `value.instance`.

Expected behavior: preserve the wrapper shape because the source constructs it to carry both prepared value and model instance.

Status: rejected; V1 correctly keeps the wrapper and changes only hashability.

Proof obligations: PO6, PO7.

## F4 - Rejected alternative: add `__bool__()`

Candidate change: add `__bool__(self): return bool(self.value)`.

Predicted result: it would make `if not value` mirror the wrapped primitive, but it would also change behavior for valid falsey prepared values such as `0`.

Expected behavior from public evidence: fix hash-based lookup. The public issue and hint do not require truthiness parity.

Status: rejected as unsupported by public intent and potentially compatibility-changing.

Proof obligations: PO7.

## F5 - Accepted domain boundary: unhashable wrapped values

Input: `W = ModelChoiceIteratorValue([], obj)`.

Observed behavior after V1: `hash(W)` raises `TypeError` through `hash(self.value)`.

Expected behavior: no stronger guarantee is required. Python dictionaries and sets require keys to be hashable, so an unhashable wrapped value is outside the hash-table lookup domain.

Status: accepted domain boundary; no source change.

Proof obligations: PO8.

## F6 - Verification honesty boundary

The proof artifacts are constructed but not machine-checked. K commands are recorded in `fvk/SPEC.md` and `fvk/PROOF.md`, but the task forbids running `kompile`, `kast`, or `kprove`.

Status: keep all tests; do not claim machine-checked verification.

Proof obligations: PO9.

## F7 - Accepted proof side condition: cooperative key equality

Input: a custom dictionary key `K` whose `K.__eq__(ModelChoiceIteratorValue(V, obj))` returns `False` even though `K.__eq__(V)` returns `True`.

Observed behavior after V1: Python dictionary lookup may fail to match such a key because hash tables compare the stored key and lookup key using Python rich comparison semantics.

Expected behavior from public evidence: the issue demonstrates an ordinary integer key, and the public hint only requires hash delegation to `self.value`. There is no public evidence requiring support for intentionally asymmetric custom keys.

Status: accepted proof side condition; no source change.

Proof obligations: PO10.
