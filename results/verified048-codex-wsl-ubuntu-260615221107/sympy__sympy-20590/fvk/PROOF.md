# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Claims

The proof uses the formal core in:

- `fvk/mini-python-slots.k`
- `fvk/symbol-slots-spec.k`

Main claims:

1. `hasInstanceDict(Basic) => false`
2. `hasInstanceDict(Symbol) => false`
3. `hasInstanceDict(ExternalNoSlotsSubclass) => true`

## Slot Layout Rules

The model encodes the Python layout rule relevant to this regression:

`hasInstanceDict(C) = hasOwnDict(slotOf(C)) or anyBaseHasDict(basesOf(C))`

`hasOwnDict(NoSlots) = true`

`hasOwnDict(EmptySlots) = false`

`hasOwnDict(NamedSlots) = false`

`anyBaseHasDict(.Classes) = false`

`anyBaseHasDict(C, CS) = hasInstanceDict(C) or anyBaseHasDict(CS)`

## Source Facts

From the V1 source:

- `slotOf(Printable) = EmptySlots`
- `basesOf(Printable) = .Classes`
- `slotOf(Basic) = NamedSlots`
- `basesOf(Basic) = Printable`
- `slotOf(Expr) = EmptySlots`
- `basesOf(Expr) = Basic`
- `slotOf(Atom) = EmptySlots`
- `basesOf(Atom) = Basic`
- `slotOf(AtomicExpr) = EmptySlots`
- `basesOf(AtomicExpr) = Atom, Expr`
- `slotOf(Boolean) = EmptySlots`
- `basesOf(Boolean) = Basic`
- `slotOf(Symbol) = NamedSlots`
- `basesOf(Symbol) = AtomicExpr, Boolean`

## Constructed Derivation For `Basic`

1. `hasInstanceDict(Basic)`
2. `= hasOwnDict(NamedSlots) or anyBaseHasDict(Printable)`
3. `= false or hasInstanceDict(Printable)`
4. `= false or (hasOwnDict(EmptySlots) or anyBaseHasDict(.Classes))`
5. `= false or (false or false)`
6. `= false`

This discharges PO-003 and PO-004.

## Constructed Derivation For `Symbol`

1. `hasInstanceDict(Symbol)`
2. `= hasOwnDict(NamedSlots) or anyBaseHasDict(AtomicExpr, Boolean)`
3. `= false or hasInstanceDict(AtomicExpr) or hasInstanceDict(Boolean)`
4. `hasInstanceDict(AtomicExpr)`
5. `= hasOwnDict(EmptySlots) or anyBaseHasDict(Atom, Expr)`
6. `= false or hasInstanceDict(Atom) or hasInstanceDict(Expr)`
7. `hasInstanceDict(Atom) = false or hasInstanceDict(Basic) = false`
8. `hasInstanceDict(Expr) = false or hasInstanceDict(Basic) = false`
9. Therefore `hasInstanceDict(AtomicExpr) = false`.
10. `hasInstanceDict(Boolean) = false or hasInstanceDict(Basic) = false`.
11. Therefore `hasInstanceDict(Symbol) = false or false or false = false`.

This discharges PO-005 and proves the intended observable: `Symbol('s')` has no
instance dictionary, so `Symbol('s').__dict__` is absent rather than `{}`.

## Constructed Derivation For Compatibility Claim

1. `hasInstanceDict(ExternalNoSlotsSubclass)`
2. `= hasOwnDict(NoSlots) or anyBaseHasDict(Printable)`
3. `= true or hasInstanceDict(Printable)`
4. `= true`

This discharges PO-006: a subclass that omits `__slots__` still gets its own
dictionary, so adding empty slots to the mixin does not globally remove dicts
from all subclasses.

## Adequacy And Completeness

The proof covers the full behavior space named by the issue: the presence or
absence of `__dict__` on `Symbol` instances due to inheritance from the printing
mixin. It also covers the public compatibility concern about subclasses that
omit slots. It does not prove unrelated SymPy expression behavior, because the
patch does not change expression semantics.

## Machine Check Commands

These commands are the expected future verification steps. They were not run in
this environment.

```sh
cd fvk
kompile mini-python-slots.k --backend haskell
kast --backend haskell symbol-slots-spec.k
kprove symbol-slots-spec.k
```

Expected outcome if the fragment and claims are accepted by the K toolchain:
`kprove` returns `#Top` for the three claims.

## Test Guidance

Do not remove tests based on this constructed proof alone. If a future
machine-check succeeds, focused in-domain tests that only assert absence of
`__dict__` on `Symbol` become redundant with the proof. Tests covering import
compatibility, pickling, printing output, and non-`Symbol` subclass behavior
should be kept because this proof does not cover them.
