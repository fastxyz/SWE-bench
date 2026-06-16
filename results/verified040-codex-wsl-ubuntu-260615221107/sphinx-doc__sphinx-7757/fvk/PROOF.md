# Constructed Proof

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## What Is Proved

For every valid parsed signature AST in the FVK domain, positional defaults are
assigned by first padding `arguments.defaults` against the combined positional
list `posonlyargs + args`. Therefore a default belonging to a positional-only
parameter is preserved in the resulting `inspect.Signature`. On the issue input
`(a, b=0, /, c=1)`, `b.default == '0'`, so the normal Python-domain rendering
path shows `b=0`.

The proof is partial over the helper's in-domain behavior. Parser termination
and full Python parser semantics are not proved; invalid signatures remain
outside the contract.

## Adequacy Gate

Inputs checked:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

Result:

The formal English claims match the public intent. No claim preserves the legacy
missing-default behavior. No API or callsite compatibility issue was found.

## Proof Sketch

1. Let `P` be positional-only arguments, `A` be ordinary positional arguments,
   and `D` be AST positional defaults.

2. Domain precondition: `0 <= len(D) <= len(P) + len(A)`.

3. V1 initializes `defaults = list(args.defaults)`, then repeatedly inserts
   `None` at the front while the defaults list is shorter than
   `len(posonlyargs) + len(args.args)`.

4. Loop invariant for padding:

   ```text
   after k insertions:
     len(defaults) = len(D) + k
     suffix(defaults, len(D)) = D
     prefix(defaults, k) = [None] * k
   ```

   When the loop exits, `k = len(P) + len(A) - len(D)`, so `defaults` is exactly
   `left_pad(None, len(P) + len(A) - len(D), D)`.

5. Positional-only construction uses `defaults[i]` for `P[i]`. By the invariant,
   this is the default attached to combined positional index `i`.

6. Ordinary positional construction uses `defaults[i + len(P)]` for `A[i]`. By
   the invariant, this is the default attached to combined positional index
   `len(P) + i`.

7. For the issue example, `P=[a,b]`, `A=[c]`, and `D=[0,1]`. Padding gives
   `[None,0,1]`. Therefore `a` receives `Parameter.empty`, `b` receives `'0'`,
   and `c` receives `'1'`.

8. `_parse_arglist()` renders default nodes for parameters whose default is not
   `Parameter.empty`. It also inserts `/` based on `Parameter.kind`; V1 does not
   alter kind assignment or separator logic.

9. Frame proof: the diff does not change vararg, keyword-only, kwarg,
   annotation, return annotation, parser invocation, or public function
   signature code paths.

## K Artifacts

Formal core:

- `fvk/mini-signature-parser.k`
- `fvk/signature-from-str-spec.k`

Reproduce the machine check later:

```sh
kompile fvk/mini-signature-parser.k --backend haskell
kast --backend haskell fvk/signature-from-str-spec.k
kprove fvk/signature-from-str-spec.k
```

Expected result after a real K run: `#Top`.

## Test Redundancy Recommendation

No existing tests should be removed based on this constructed proof. The proof
has not been machine-checked, and it is scoped to the helper's AST-level default
alignment rather than the whole Sphinx build pipeline.

Recommended tests to keep or add in the fixed public suite:

- Keep existing ordinary-default, keyword-only, and positional-only kind tests.
- Add a focused public regression test for
  `signature_from_str('(a, b=0, /, c=1)')`.
- Add or keep a Python-domain rendering regression for
  `.. py:function:: foo(a, b=0, /, c=1)`.

## Residual Risk

The trusted base is the adequacy of the AST-level mini model, Python's AST
default alignment convention, the static source reading, and a future real K
toolchain run. The proof is constructed but not machine-checked in this session.
