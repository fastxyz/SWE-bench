# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Pipeline length cardinality

For any `Pipeline` whose `steps` sequence has cardinality `N >= 0`,
`Pipeline.__len__` returns `N`.

Evidence: E1, E3, E4.

Formal claim: `LEN` in `fvk/pipeline-len-spec.k`.

Discharge argument: V1 executes `return len(self.steps)`. Under Python's length
convention for sized sequences, `len(self.steps)` is exactly the cardinality
`N`.

## PO-2: Full slice after length

For any `Pipeline` whose `steps` sequence has cardinality `N >= 0`,
`pipe[:len(pipe)]` is evaluable and represents the full step sequence.

Evidence: E2, E5.

Formal claim: `FULL-SLICE-AFTER-LEN` in `fvk/pipeline-len-spec.k`.

Discharge argument: `len(pipe)` rewrites to `N` by PO-1. Existing slice handling
delegates to `self.steps[ind]`; a prefix slice with stop `N` over a sequence of
length `N` returns the complete sequence.

## PO-3: Minimal sequence protocol change

The production patch must not add unrelated sequence behavior such as
`__iter__`.

Evidence: E6.

Discharge argument: the repo diff adds only `Pipeline.__len__` and does not
change `__getitem__` or add other data-model methods.

## PO-4: Public compatibility

Adding `__len__` must not break valid public `Pipeline` instances through a
signature, dispatch, return-shape, or truthiness incompatibility.

Evidence: E4, E7.

Discharge argument: `__len__(self)` is a new data-model method with no caller
signature changes. Valid constructed pipelines are non-empty, so their
truthiness remains true after adding `__len__`.

## PO-5: Adequacy of formalization

The K claims must express the public intent rather than only restating V1.

Evidence: `fvk/INTENT_SPEC.md`, `fvk/FORMAL_SPEC_ENGLISH.md`, and
`fvk/SPEC_AUDIT.md`.

Discharge argument: every formal-English claim maps to a public issue,
docstring, source-compatibility, or named Python sequence convention entry.
No required behavior is marked fail or ambiguous.
