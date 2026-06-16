# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Existing equality to primitive

Claim: For `W = ModelChoiceIteratorValue(V, O)` and object `X`, `W == X` returns `V == X`.

Discharge: source inspection of `__eq__()` shows it returns `self.value == other` unless `other` is another wrapper, in which case it first unwraps `other.value`.

Finding links: F2.

## PO2 - Hash of wrapper equals hash of wrapped value

Claim: If `hash(V)` returns `H`, then `hash(ModelChoiceIteratorValue(V, O))` returns `H`.

Discharge: V1 source has `def __hash__(self): return hash(self.value)`.

Finding links: F1.

## PO3 - Python hash/equality coherence

Claim: For any hashable `X`, if `ModelChoiceIteratorValue(V, O) == X`, then the wrapper hash equals the hash needed for dictionary lookup under Python's hash/equality contract for `V`.

Discharge: PO1 reduces equality to `V == X`; PO2 reduces wrapper hash to `hash(V)`; Python's dictionary contract requires equal hashable keys to have equal hashes.

Finding links: F1, F2.

## PO4 - Dictionary membership does not raise for hashable wrapped value

Claim: For `W = ModelChoiceIteratorValue(1, O)` and dictionary `D = {1: Payload}`, evaluating `W in D` computes `hash(W)`, does not raise, and reaches the equality comparison path.

Discharge: PO2 gives `hash(W) == hash(1)`, so the hash computation is defined. Dictionary lookup can proceed to equality comparison.

Finding links: F1.

## PO5 - Dictionary membership and getitem find the equal key

Claim: For `W = ModelChoiceIteratorValue(V, O)` and dictionary entry `K -> Payload`, if `hash(K) == hash(V)` and Python equality between `K` and `W` resolves true, then `W in D` is true and `D[W] == Payload`.

Discharge: PO2 supplies the same hash bucket as `V`; PO1 and Python reverse comparison semantics allow the stored key and wrapper to compare equal when the stored key's comparison returns `NotImplemented` or delegates. This matches the issue's integer-key example. Deliberately asymmetric custom keys are separated into PO10.

Finding links: F1.

## PO6 - Wrapper payload frame condition

Claim: The fix does not change `.value`, `.instance`, `__str__()`, `__eq__()`, `ModelChoiceIterator.choice()`, or widget option context shape.

Discharge: V1 adds only `__hash__()` to `ModelChoiceIteratorValue`.

Finding links: F3.

## PO7 - Public compatibility

Claim: No public callsite, override, or signature change is required or introduced.

Discharge: adding `__hash__()` changes only hash protocol behavior for the existing object. No method signature or returned data structure is changed.

Finding links: F3, F4.

## PO8 - Unhashable wrapped value boundary

Claim: If `hash(V)` raises `TypeError`, then `hash(ModelChoiceIteratorValue(V, O))` may also raise `TypeError`.

Discharge: V1 delegates directly to `hash(self.value)`. This is consistent with Python hash-table domains because unhashable values cannot be dictionary or set keys.

Finding links: F5.

## PO9 - Honesty gate

Claim: The constructed proof is not machine-checked and does not justify removing tests.

Discharge: the task forbids running tests, Python, or K tooling. Artifacts record expected commands only.

Finding links: F6.

## PO10 - Cooperative key equality side condition

Claim: The dictionary-membership proof is scoped to ordinary keys, including the issue's integer key, and to custom keys whose equality with the wrapper agrees with equality to the wrapped primitive.

Discharge: public evidence names only an integer-key dictionary and the public hint names only hash delegation. There is no intent evidence for overriding arbitrary asymmetric custom-key comparison behavior.

Finding links: F7.
