# Intent Specification

Status: constructed, not machine-checked.

Intent-only obligations from public evidence:

1. A derived test class must inherit class-level marks from every marked base in
   its MRO. For the issue example, `TestDings(Foo, Bar).test_dings` must have
   both `foo` and `bar`.
2. Mark inheritance through ordinary single inheritance remains a supported
   pytest feature.
3. Applying a mark to a subclass must not mutate base classes and must not make
   sibling subclasses inherit that subclass mark.
4. The fix is about class mark lookup. Function and module mark lookup should
   keep existing behavior.
5. Existing invalid marker validation remains in force.

Ambiguities:

- Public evidence does not settle sibling-base list order for multiple
  inheritance.
- Public evidence does not require arbitrary metaclass `pytestmark` descriptors
  to remain supported as a marker source.
