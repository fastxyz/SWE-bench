# Formal Spec English

This file paraphrases the nontrivial claims in `model-choice-iterator-value-spec.k`.

C1. Hash claim: for any wrapper `W = ModelChoiceIteratorValue(V, O)`, if `V` is hashable and `hash(V) = H`, then `hash(W)` returns `H`.

C2. Primitive equality claim: for any wrapper `W = ModelChoiceIteratorValue(V, O)` and any object `X`, `W == X` returns the same result as `V == X`.

C3. Wrapper equality claim: for wrappers `W1 = ModelChoiceIteratorValue(V1, O1)` and `W2 = ModelChoiceIteratorValue(V2, O2)`, `W1 == W2` returns the same result as `V1 == V2`. The model instance does not participate in equality.

C4. Dictionary membership claim: for a dictionary with a hashable key `K`, if `hash(K) == hash(V)` and Python equality between `K` and `ModelChoiceIteratorValue(V, O)` resolves true as it does for the issue's integer key, then membership queried by the wrapper returns true and does not raise `TypeError`.

C5. Dictionary getitem claim: for a dictionary entry `K -> Payload`, if `hash(K) == hash(V)` and Python equality between `K` and `ModelChoiceIteratorValue(V, O)` resolves true as it does for the issue's integer key, then lookup by the wrapper returns `Payload` and does not raise `TypeError`.

C6. Frame claim: adding `__hash__()` does not change object construction, `.value`, `.instance`, `__str__()`, `__eq__()`, `ModelChoiceIterator.choice()`, or `ChoiceWidget.create_option()` signatures and return shapes.

C7. Domain claim: if `V` is not hashable, the wrapper is not required to become hashable; raising `TypeError` from `hash(V)` is consistent with Python dictionary/set key requirements.
