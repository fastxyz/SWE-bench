# Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Decision

V1 stands with no source-code changes in this FVK pass.

## Why

- F1 and PO1 show that the reported `self.a = a` from `a: str = None` path is
  repaired by adding parameter annotation inference to `instance_attrs_type`.
- F2 and PO2 show that the same annotation evidence is also collected for
  annotated assignment targets, which is a small consistent extension of the
  issue intent.
- PO5 and PO6 show that existing value inference and association behavior are
  preserved because V1 augments the existing maps rather than changing the
  renderer or map shape.
- F4 and the compatibility audit show no public signature or producer/consumer
  compatibility break.

## Recommended Future Work

- Add public tests for `def __init__(self, a: str = None): self.a = a`.
- Add public tests for `self.a: str = None` and class/local annotated
  assignments if the project wants that behavior locked down.
- If full PEP 484 output is desired, write a new spec for complex annotation
  rendering before changing code. Include explicit expected UML strings for
  `Optional[T]`, `Union`, generic containers, forward references, and type
  comments.

## Do Not Do In This Pass

- Do not modify tests.
- Do not replace pyreverse's existing inferred-node map with annotation strings.
- Do not claim complete PEP 484 formatting coverage from this proof.
