# Proof Obligations

Status: all obligations discharged by constructed proof; not machine-checked.

PO-001: Intent adequacy for order.

* Claim: reverse iteration must produce the opposite of `OrderedSet` insertion
  order.
* Evidence: E-001, E-002, E-003.
* Discharge: K-002 states `reverseList(uniqueFirst(XS))`, and `SPEC_AUDIT.md`
  marks the claim as matching intent.

PO-002: Representation invariant.

* Claim: the backing dictionary keys are exactly the ordered set contents in
  insertion order.
* Evidence: E-004.
* Discharge: K model uses `dictFromKeys(XS) => uniqueFirst(XS)` and
  `iter(os(KS)) => KS`.

PO-003: Method correctness.

* Claim: `OrderedSet.__reversed__()` returns a reverse iterator over the backing
  dictionary's keys.
* Evidence: V1 source code `return reversed(self.dict)`; E-005 supports runtime
  availability.
* Discharge: K model uses `reversed(os(KS)) => dictReversedKeys(KS)` and
  `dictReversedKeys(KS) => reverseList(KS)`.

PO-004: Frame condition.

* Claim: reverse iteration does not mutate the set.
* Evidence: `__reversed__()` only reads `self.dict` and returns an iterator.
* Discharge: the K semantics for `reversed(os(KS))` returns `reverseList(KS)`
  without rewriting `os(KS)`.

PO-005: Boundary and duplicate cases.

* Claim: empty sets reverse to empty, singleton sets reverse to themselves, and
  duplicate constructor inputs expose only distinct set contents.
* Evidence: E-003, E-004.
* Discharge: concrete K witness claims cover empty input and `[1, 2, 1]`.

PO-006: Runtime domain.

* Claim: using `reversed(self.dict)` is within the supported Python domain.
* Evidence: E-005.
* Discharge: the proof assumes Python `>=3.8`; no broader runtime is required by
  this checkout.

PO-007: Public compatibility.

* Claim: adding `__reversed__()` does not break existing `OrderedSet` API users.
* Evidence: existing methods and signatures are unchanged.
* Discharge: `PUBLIC_COMPATIBILITY_AUDIT.md` reports pass.
