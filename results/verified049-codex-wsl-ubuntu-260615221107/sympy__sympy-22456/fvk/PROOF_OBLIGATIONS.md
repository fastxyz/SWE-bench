# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Basic-compatible argument carrier

For every `String` subclass `C` and Python string `s`, construction `C(s)` must
produce an object with:

- `text == s`
- `args == (Str(s),)`
- every `arg in args` is a `Basic`

Evidence: E1-E6. Disposition: discharged by source inspection of
`String.__new__` and `_construct_text`.

## PO2: Positional reconstruction invariant

For every object from PO1:

```python
obj.func(*obj.args) == obj
```

Proof sketch obligation: `obj.args` supplies `Str(s)`; `C(Str(s))` normalizes to
`text == s`; `Token.__eq__` compares class and slot values, so equality holds.

Evidence: E1, E2, E6. Disposition: discharged by V1.

## PO3: Keyword reconstruction frame

For every object from PO1:

```python
obj.func(**obj.kwargs()) == obj
```

Evidence: E5. Disposition: discharged because `.text` remains the public string
and `Token.kwargs()` still reads slots.

## PO4: Invalid text behavior frame

For every public input `x` that is neither a Python `str` nor a `Str`,
`String(x)` must raise `TypeError` through `_construct_text`.

Evidence: I4 and the pre-existing constructor contract. Disposition: discharged
because V1 only adds the `Str` case before the existing type check.

## PO5: Codegen atom-leaf frame

For default `atoms()` on a codegen `Token` tree, if traversal reaches a
`String` object it must return that `String` as an atom and must not expose its
internal `Str` argument as a default atom.

Evidence: E5, E7. Disposition: discharged by the `Token.atoms()` override.

## PO6: Public compatibility and subclass inheritance

Constructor signature, public `.text`, `kwargs()`, `str`, `repr`, and subclass
behavior must remain compatible with public callsites and tests.

Evidence: E5, E7 and the public callsite search summarized in
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`. Disposition: discharged by static audit.

## PO7: Honesty and reproducibility

Because execution is forbidden, the proof must be labeled constructed, not
machine-checked, and must include exact commands for later `kompile`, `kast`,
and `kprove` execution.

Evidence: FVK docs. Disposition: discharged in `fvk/PROOF.md`.
