# Iteration Guidance

## Decision

V1 stands unchanged.

The FVK audit found the reported defect localized to `Float.__eq__` and confirmed that V1 discharges the key obligation by rejecting already-SymPy Boolean operands before the zero-Float shortcut. No additional source edit is justified by the public intent.

## Why no code change is needed

Finding F1 maps directly to PO1, and V1 discharges PO1 with the early `isinstance(other, Boolean)` return.

Finding F2 explains why the narrower V1 structure is preferable to moving the post-sympification guard wholesale: it avoids changing native `False` as part of an issue about `S.false`.

Finding F3 confirms that changing `BooleanAtom` or `Basic` is unnecessary because the reverse comparison already has the expected result.

Finding F4 confirms that numeric Float comparison branches are framed and unchanged.

## Recommended next work

If tests become editable in a normal development task, add focused regression coverage for `S(0.0) != S.false` and `S.false != S(0.0)`. Keep the existing native-bool and integer/SymPy-Boolean distinction tests.

If a future issue asks whether `Float(0.0) == False` should mirror `S(0) == False`, handle that as a separate public-intent question. The current issue does not justify broadening or removing native bool compatibility.

## Residual risk

The proof is constructed over a category-level mini model of `Float.__eq__`, not the full Python or SymPy runtime. This is adequate for the Boolean-vs-zero dispatch defect because the model preserves the discriminating operand categories, but it is not a machine-checked proof of every branch in `numbers.py`.

The emitted K commands in `PROOF.md` remain to be run in an environment where K tooling is available.

