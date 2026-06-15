# SPEC

Status: FVK constructed proof package, not machine-checked.

## Target

The audited source behavior is the interaction between:

- `repo/django/forms/widgets.py`: `CheckboxInput.get_context()`
- `repo/django/contrib/postgres/forms/array.py`: `SplitArrayWidget.get_context()`

The public issue is that `SplitArrayField(BooleanField)` rendered every checkbox after the first true initial value as checked because `CheckboxInput.get_context()` mutated the attrs dictionary reused by `SplitArrayWidget`.

## Public Intent Ledger Summary

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The controlling obligations are:

- E1/E2: later split-array boolean widgets must not inherit generated `checked` from an earlier true value.
- E3: `CheckboxInput.get_context()` must not mutate the attrs dictionary passed into it.
- E4: `check_test(value)` determines whether `CheckboxInput` generates `checked`.
- E5/E6: `Widget.get_context()` builds returned attrs while `SplitArrayWidget` reuses `final_attrs` for child widgets.
- E7: public call signatures must remain compatible.

## Domain and Abstraction

The concrete issue domain is boolean split-array rendering with preexisting data. The formal model abstracts:

- a BooleanField prepared value as `Bool`;
- the original attrs dictionary as `attrs(C)`, where `C` means the caller explicitly supplied `checked`;
- the split-array observable as the ordered list of checked flags returned by child contexts.

This abstraction preserves the property under test: it distinguishes the failing case `[False, True, False] -> [False, True, True]` from the intended case `[False, True, False] -> [False, True, False]`.

## Intended Contracts

### CheckboxInput Context

For any normal return of `CheckboxInput.get_context(name, value, attrs)`:

1. If `check_test(value)` is true, the returned widget context has `checked`.
2. If `check_test(value)` is false, the returned widget context has `checked` only when the original attrs or widget attrs explicitly supplied it.
3. The caller-owned `attrs` object is not mutated by generated `checked`.
4. Non-`checked` attrs are preserved in the returned context.

V1 implements this by copying non-`None` attrs before assigning `attrs['checked'] = True`.

### SplitArrayWidget with CheckboxInput

For split-array values `v_0 ... v_n` and original attrs `A`, each subwidget `i` is checked exactly when:

`A` explicitly contained `checked`, or `CheckboxInput.check_test(v_i)` is true.

No subwidget may be checked solely because an earlier subwidget generated `checked`. Missing values map to `None`, for which the default checkbox check test is false.

### Compatibility

V1 must not change method signatures, return shape, names, ids, templates, localization propagation, or `value_from_datadict()` behavior. The source diff is limited to copying attrs before the generated `checked` assignment, so these frame conditions are preserved.

## Formal Artifacts

- `fvk/mini-django-widgets.k`: mini-K semantics for the attrs aliasing and split render loop.
- `fvk/checkbox-splitarray-spec.k`: K claims for no attrs mutation, split-array per-index independence, and the concrete `[False, True, False]` reproduction.
- `fvk/FORMAL_SPEC_ENGLISH.md`: English paraphrase of each formal claim.
- `fvk/SPEC_AUDIT.md`: adequacy comparison against this intent spec.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: signature/callsite compatibility audit.
