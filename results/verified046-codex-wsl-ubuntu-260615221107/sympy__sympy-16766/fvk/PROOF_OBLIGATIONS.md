# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were executed.

## PO-001: Indexed subscript rendering

Claim: for an `Indexed` expression whose base is an `IndexedBase` with printable
label `B` and whose indices are printable in order as `I_1, ..., I_n`,
`PythonCodePrinter._print_Indexed` returns:

```text
print(B) + "[" + print(I_1) + ", " + ... + ", " + print(I_n) + "]"
```

Representative K claim:

```k
claim render(Indexed(IndexedBase(Sym("p")), IntLit(0))) => "p[0]"
```

Evidence: E-001 through E-004 in `SPEC.md`.

Discharge status: constructed proof in `PROOF.md`, section PO-001.

## PO-002: Idx label rendering

Claim: for `Idx(L)` with printable label `L`, `PythonCodePrinter._print_Idx`
returns `print(L)`.

Representative K claim:

```k
claim render(Indexed(IndexedBase(Sym("A")), Idx(Sym("i")))) => "A[i]"
```

Evidence: E-005 and the dependent-case analysis in F-002.

Discharge status: constructed proof in `PROOF.md`, section PO-002.

## PO-003: Index order and separator

Claim: `_print_Indexed` preserves `expr.indices` order and inserts exactly
comma-space between adjacent rendered indices.

Representative K claim:

```k
claim render(Indexed(IndexedBase(Sym("A")), Sym("i") "," Sym("j")))
  => "A[i, j]"
```

Evidence: E-003 and E-004.

Discharge status: constructed proof in `PROOF.md`, section PO-003.

## PO-004: Unsupported-set preservation for supported Indexed/Idx

Claim: on the supported domain, dispatch to `_print_Indexed` and `_print_Idx`
does not call `_print_not_supported`, so `CodePrinter.doprint` does not add
`Indexed` or `Idx` to `_not_supported`.

Reasoning target:

```text
Printer._print(Indexed(...))
  chooses PythonCodePrinter._print_Indexed
  before CodePrinter._print_Expr

Printer._print(Idx(...))
  chooses PythonCodePrinter._print_Idx
  before CodePrinter._print_Expr
```

Evidence: E-006 and E-007.

Discharge status: constructed proof in `PROOF.md`, section PO-004.

## PO-005: Compatibility and inheritance

Claim: V1 does not change public method signatures, and the new methods are
ordinary printer overrides inherited by Python printer subclasses that derive
from `PythonCodePrinter`, including `LambdaPrinter`.

Evidence: E-008 and the public compatibility audit in `SPEC.md`.

Discharge status: constructed proof in `PROOF.md`, section PO-005.

## PO-006: Honesty gate

Claim: the proof is constructed, not machine-checked. Test deletion is not
justified by this pass. The commands that would check the artifacts are:

```sh
kompile fvk/mini-python-printer.k --backend haskell
kast --backend haskell fvk/pycode-indexed-spec.k
kprove fvk/pycode-indexed-spec.k
```

Evidence: FVK `verify.md` honesty gate and this task's no-execution constraint.

Discharge status: open verification caveat, not a code defect.
