# Iteration Guidance

Status: FVK repair decision for V2.

## Source Decision

Keep V1 unchanged. The FVK findings and proof obligations identify the missing case as a `Pow` denominator base in `_print_Mul`, and V1 already implements the required source change:

```python
isinstance(item.base, (Mul, Pow))
```

No additional source edit is justified by the public intent.

## Why No Parser Change

`FINDINGS.md` F3 and `PROOF_OBLIGATIONS.md` PO1 show that the parser already constructs a grouped expression tree. Changing parser construction would address the wrong layer and risk unrelated behavior.

## Why No Broader Printer Change

`FINDINGS.md` F4-F5 and `PROOF_OBLIGATIONS.md` PO4-PO6 bound the repair to the existing string-printer denominator guard. Other printers may have similar-looking code, but the public issue and evidence target the `str()` output shown from `parse_latex`; no public-intent evidence requires changing code printers or LaTeX output.

## Recommended Tests for Maintainers

Do not modify tests in this benchmark task. For a normal upstream patch, add source tests equivalent to:

```python
assert str(Mul(x, Pow(1/y, -1, evaluate=False), evaluate=False)) == 'x/(1/y)'
assert str(parse_latex(r"\frac{a}{\frac{1}{b}}")) == 'a/(1/b)'
assert str(parse_latex(r"\frac{\frac{a^3+b}{c}}{\frac{1}{c^2}}")) == '((a**3 + b)/c)/(1/(c**2))'
```

Keep existing issue 14160 and simple quotient tests.

## Remaining Caveat

The formal proof is constructed but not machine-checked because the task forbids K tooling. The code conclusion rests on source inspection plus the constructed proof obligations, not on executed tests or `kprove`.
