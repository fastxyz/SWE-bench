# FVK Specification

Status: constructed from public intent and source inspection; not
machine-checked. No tests, Python imports, or K tooling were run.

## Scope

The audited behavior is the instance layout effect of the printing mixin on
`sympy.Symbol('s').__dict__`. The observable property is whether a `Symbol`
instance has an inherited instance dictionary. Algebraic behavior, printing
output text, evaluation, hashing, and assumption inference are outside this
spec because the V1 patch does not change those methods or data flows.

Supplemental formal core:

- `fvk/mini-python-slots.k` models the Python slot/dict layout fragment needed
  for this regression.
- `fvk/symbol-slots-spec.k` gives the source-specific class graph and claims.

## Public Intent Ledger

| ID | Source | Evidence | Semantic Obligation | Status |
| -- | -- | -- | -- | -- |
| I-001 | `benchmark/PROBLEM.md` | "In version 1.6.2 Symbol instances had no `__dict__` attribute" | `Symbol('s').__dict__` must be absent, raising `AttributeError`. | Encoded by claim `hasInstanceDict(Symbol) => false`. |
| I-002 | `benchmark/PROBLEM.md` | "`sympy.Symbol('s').__dict__` now exists (and returns an empty dict)" | The current/regressed empty dictionary behavior is the bug, not compatibility to preserve. | Recorded as Finding F-001. |
| I-003 | `benchmark/PROBLEM.md` | "introduced because some parent class accidentally stopped defining `__slots__`" | The fix should restore slots on the parent that contributes the dictionary. | Encoded by `slotOf(Printable) => EmptySlots`. |
| I-004 | public hint in `benchmark/PROBLEM.md` | "we should add empty slots to DefaultPrinting" | The intended slot declaration is empty, not a new stored field. | Encoded by `EmptySlots` for `Printable`/`DefaultPrinting`. |
| I-005 | public hint in `benchmark/PROBLEM.md` | "Adding `__slots__` won't affect subclasses - if a subclass does not specify `__slots__`, then the default is to add a `__dict__` anyway." | Preserve default dictionaries for subclasses that omit slots. | Encoded by compatibility claim `ExternalNoSlotsSubclass => true`. |
| I-006 | source: `sympy/printing/defaults.py` | `DefaultPrinting = Printable` | `DefaultPrinting` is an alias, so the layout-bearing class to change is `Printable`. | Encoded by source change and proof obligation PO-003. |
| I-007 | source: `sympy/core/basic.py` | `class Basic(Printable, ...)` with `__slots__ = (...)` | `Basic` should not get a dictionary from `Printable`. | Encoded by claim `hasInstanceDict(Basic) => false`. |
| I-008 | source: `sympy/core/symbol.py`, `expr.py`, `boolalg.py`, `evalf.py` | `Symbol`, `AtomicExpr`, `Expr`, `Atom`, `Boolean`, and `EvalfMixin` define slots. | No other public base on the `Symbol` path should introduce `__dict__`. | Encoded by the class graph in `symbol-slots-spec.k`. |

## Intent-Only Contract

For every ordinary construction of `Symbol` in this source tree:

1. `Symbol` instances must not have an instance `__dict__`.
2. The absence must be achieved by restoring empty slots on the printing mixin
   that became a parent of `Basic`.
3. The printing mixin must remain a printing-method provider with no instance
   state.
4. Subclasses of the printing mixin that omit `__slots__` remain allowed to have
   ordinary instance dictionaries by Python's default class-layout rule.
5. No public method signature, return type, printing behavior, or constructor
   protocol is intentionally changed by this fix.

## Formal Model

The mini semantics abstracts Python class layout to the one axis the defect
manipulates:

- `NoSlots` means a class declaration omits `__slots__` and therefore provides
  an instance dictionary.
- `EmptySlots` and `NamedSlots` mean a class declaration defines `__slots__` and
  does not itself provide an instance dictionary.
- `hasInstanceDict(C)` is true iff `C` provides its own dict or any base class
  recursively provides one.

This abstraction is property-complete for the issue because it distinguishes a
passing instance (`hasInstanceDict(Symbol) == false`) from the failing one
(`hasInstanceDict(Symbol) == true`). It intentionally omits method bodies and
metaclass behavior because those are not contributors to the reported
observable.

## K Claims In English

`hasInstanceDict(Basic) => false`: after V1, `Printable` has empty slots and
`Basic` has named slots, so `Basic` does not inherit or provide an instance
dictionary.

`hasInstanceDict(Symbol) => false`: after V1, every class on the `Symbol` MRO
path represented in the model has `EmptySlots` or `NamedSlots`, so no base
contributes an instance dictionary and `Symbol('s').__dict__` is absent.

`hasInstanceDict(ExternalNoSlotsSubclass) => true`: a subclass that omits
`__slots__` still has its own instance dictionary even though `Printable` now
has empty slots.

## Adequacy Audit

All three claims are entailed by the public intent ledger:

- The `Symbol` no-dict claim matches I-001 through I-004 and I-008.
- The `Basic` no-dict claim is necessary because `Basic` is the inheritance
  bridge from `Printable` to `Symbol` (I-006, I-007).
- The external subclass compatibility claim matches I-005 and prevents the spec
  from overclaiming that every `Printable` subclass loses `__dict__`.

No claim preserves the suspect legacy behavior in I-002.

## Public Compatibility Audit

Changed public symbol: `Printable` from `sympy.core._print_helpers`, publicly
aliased as `sympy.printing.defaults.DefaultPrinting`.

Compatibility status:

- Method signatures are unchanged: `__str__`, `__repr__`, `_repr_disabled`,
  `_repr_png_`, `_repr_svg_`, and `_repr_latex_` are untouched.
- Import compatibility is unchanged: `DefaultPrinting = Printable` remains.
- Subclasses without `__slots__` still receive their own instance dictionary;
  this is encoded by the compatibility claim.
- Slotted subclasses of `Printable` lose an inherited dictionary. That is not a
  compatibility regression under the public intent; it is the intended repair.
