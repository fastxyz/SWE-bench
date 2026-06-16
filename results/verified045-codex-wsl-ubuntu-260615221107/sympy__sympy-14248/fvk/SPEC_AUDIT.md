# Spec Audit

Status: adequacy check between `INTENT_SPEC.md` and
`FORMAL_SPEC_ENGLISH.md`.

| Formal claim | Intent items | Result | Notes |
|---|---|---|---|
| `JOIN-LOOP` | I-001, I-004 | pass | The loop invariant states the subtraction-style sign discipline for every term in the list, not just the reproducer. |
| `STR-MATADD` | I-001, I-003, I-004 | pass | Covers the `print`/`str` path named by the issue and forbids explicit unit negative coefficients in rendered negative terms. |
| `LATEX-MATADD` | I-001, I-003, I-004 | pass | Covers the `latex` path named by the issue and forbids `-1 B` for unit negative terms. |
| `PRETTY-MATADD` | I-001, I-003, I-004 | pass | Covers the `pprint` path named by the issue and forbids `+ -A*B` sign structure. |
| Frame: internal representation unchanged | I-002, I-006 | pass | The formal spec and V1 code treat `MatAdd`/`MatMul` representation as input state and change only rendering. |
| Frame: argument ordering preserved | I-005 | pass | Public intent does not require a new ordering rule; preserving `expr.args` is an explicit frame condition rather than a proof of a new order. |
| Frame: API compatibility | I-006 | pass | No method signature or public expression type is changed. |

No fail or ambiguous entries block `V2 == V1`.
