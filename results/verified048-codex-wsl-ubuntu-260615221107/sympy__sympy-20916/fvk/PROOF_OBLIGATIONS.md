# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Regex denotes the intended base-plus-digit language

Claim: Python regex `^([^\W\d_]+)([0-9]+)$` matches exactly a non-empty
`BaseRun` followed by a non-empty ASCII `DigitRun`, and its two capture groups
are `(BaseRun, DigitRun)`.

Evidence: SPEC definitions and intent I3.

Discharge status: constructed by regex character-class semantics.

## PO-2: Greek Unicode letters satisfy `BaseChar`

Claim: A Greek letter such as `ω` is matched by Python regex `\w`, is not
matched by `\d`, and is not `_`; therefore it satisfies `BaseChar`.

Evidence: issue examples I1/I2 and Unicode-word requirement I3.

Discharge status: constructed by Python 3 Unicode regex semantics.

## PO-3: ASCII multi-digit suffixes stay intact

Claim: For `x10`, the matcher captures base `x` and digit suffix `10`.

Evidence: existing ASCII suffix behavior I4.

Discharge status: constructed from PO-1, because digits are excluded from the
base class and the suffix class accepts one or more ASCII digits.

## PO-4: The fix does not broaden the implicit base to digits or underscore

Claim: Names whose first part contains internal digits or underscore do not
satisfy `BaseRun` unless public intent later broadens the domain.

Evidence: I4/I5 preserve the old letter-plus-digits shape and explicit
underscore separators.

Discharge status: constructed from PO-1.

## PO-5: Pretty printing renders captured digit suffixes as subscripts

Claim: Once `split_super_sub("ω0")` returns `("ω", [], ["0"])`,
`pretty_symbol("ω0")` in unicode mode renders the digit using `sub["0"]`, so
the observable output contains `ω₀`.

Evidence: implementation consumer I6 and prompt output obligation I1/I2.

Discharge status: constructed by source inspection of `pretty_symbol` and its
digit subscript table.

## PO-6: Existing explicit separator behavior is framed

Claim: The V1 edit does not change the scan that handles `_`, `^`, and `__`,
nor the public return shape `(name, supers, subs)`.

Evidence: source diff and public tests I5.

Discharge status: constructed by source diff inspection.

## PO-7: Proof honesty and reproduction

Claim: The FVK proof is only constructed until these commands are run and
return `#Top`:

```sh
cd fvk
kompile mini-symbol-conventions.k --backend haskell
kast --backend haskell symbol-conventions-spec.k
kprove symbol-conventions-spec.k
```

Evidence: FVK verify honesty gate.

Discharge status: open by design in this benchmark session; commands were not
run.
