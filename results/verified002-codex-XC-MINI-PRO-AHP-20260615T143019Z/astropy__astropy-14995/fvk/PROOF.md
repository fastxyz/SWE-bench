# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## What is proved

For `_arithmetic_mask`, if and when the helper returns:

- no masks plus callable `handle_mask` returns no mask;
- exactly one present mask returns a deep copy of that mask;
- both present masks delegate to the callable;
- `handle_mask=None` disables mask propagation;
- binary scalar arithmetic with a masked left operand follows the exactly-one
  mask rule because the scalar operand is wrapped as a maskless operand.

## Symbolic proof sketch

The helper has no loops. The proof is case analysis over the branch predicates:
`handle_mask is None`, `self.mask is None`, `operand is None`, and
`operand.mask is None`.

1. If `handle_mask is None`, the first source branch returns `None`; this proves
   PO-5 and `MASK-NONE-HANDLE`.
2. If `handle_mask` is callable, `self.mask is None`, and the operand is absent
   or has `operand.mask is None`, every path returns `None`; this proves PO-1.
3. If `handle_mask` is callable, `self.mask is None`, and `operand.mask` is
   present, the second branch returns `deepcopy(operand.mask)`; this proves
   PO-2.
4. If `handle_mask` is callable, `self.mask` is present, and the operand is
   absent or has `operand.mask is None`, the V1 branch returns
   `deepcopy(self.mask)`; this proves PO-3.
5. If `handle_mask` is callable and both masks are present, none of the
   zero-mask or one-mask branches applies, so execution reaches
   `handle_mask(self.mask, operand.mask, **kwds)`; this proves PO-4.
6. The binary scalar caller model rewrites
   `binaryCallableMask(self_mask, NoMask)` to `_arithmetic_mask(self_mask,
   operand(NoMask), CallableMask)`, then uses step 4; this proves PO-6.
7. Because the copy branches use `deepcopy` and never inspect mask contents,
   present masks remain present masks with their original value domain; this
   proves PO-7.

## Machine-check commands to run later

These commands are expected to produce `#Top` from `kprove` after the K files are
checked in an environment with the K framework installed. They are listed only;
they were not run.

```sh
kompile fvk/mini-python-mask.k --backend haskell
kast --backend haskell fvk/ndarithmetic-mask-spec.k
kprove fvk/ndarithmetic-mask-spec.k --definition fvk/mini-python-mask-kompiled
```

## Test-redundancy recommendation

No tests were removed or edited. Because the proof is constructed but not
machine-checked, any future recommendation to remove point tests is conditional
on `kprove` returning `#Top`. In this benchmark, the useful test guidance is to
keep or add coverage for:

- masked left operand times maskless right operand with `handle_mask=np.bitwise_or`;
- masked left operand times scalar with `handle_mask=np.bitwise_or`;
- boolean mask with default `handle_mask`;
- maskless left operand times masked right operand;
- both operands maskless.

## Residual risk

The trusted base is the adequacy of the small mask-state K abstraction, the
manual correspondence between source branches and K rules, and future execution
of the emitted K commands. The proof covers mask propagation behavior, not
numeric data arithmetic, WCS, metadata, uncertainty propagation, performance, or
integration behavior.
