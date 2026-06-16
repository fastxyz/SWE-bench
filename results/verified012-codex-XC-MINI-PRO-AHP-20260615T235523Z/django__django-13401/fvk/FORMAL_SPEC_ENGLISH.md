# Formal Spec In English

Status: constructed, not machine-checked.

FE1. `fieldEq(f, g)` is true exactly when both operands are fields with the
same `creation_counter` and the same owner model key. If two fields have the
same counter but different owner models, equality is false.

FE2. `fieldHashKey(f)` is the pair `(creation_counter, owner model key)`.
Therefore, whenever `fieldEq(f, g)` is true, `fieldHashKey(f)` and
`fieldHashKey(g)` are the same.

FE3. For the abstract-base reproduction, the copied fields on `B` and `C` have
the same copied `creation_counter` but different owner model keys. The spec
therefore gives `fieldEq(B.myfield, C.myfield) == false`, and set insertion
retains both elements.

FE4. `fieldLt(f, g)` compares `creation_counter` first. If counters differ,
the model is ignored and the result is exactly the counter comparison.

FE5. If counters are equal, `fieldLt(f, g)` compares a model sort key. An
unattached field sorts before an attached field. Attached fields sort by model
label and then by a model identity component, matching V1's
`(model._meta.label_lower, id(model))` tie-breaker.

FE6. No public signatures, return protocols, or subclass dispatch contracts are
changed by the proof target.
