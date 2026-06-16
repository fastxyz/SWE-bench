# FVK Proof

Status: constructed, not machine-checked.

## Claims proved

The constructed proof covers:

- `CLAIM-MRO-COMPLETE`: class mark lookup includes all direct `pytestmark`
  entries from the class MRO.
- `CLAIM-OWN-ONLY-STORE`: `store_mark` stores only direct marks on the decorated
  class, avoiding duplication when MRO lookup later runs.
- `CLAIM-NONCLASS-FRAME`: non-class lookup keeps the original behavior.
- `CLAIM-INVALID-FRAME`: invalid mark entries still flow to
  `normalize_mark_list`.

Formal artifacts:

- `fvk/mini-python-marks.k`
- `fvk/mark-mro-spec.k`

Machine-check commands, not executed:

```sh
kompile fvk/mini-python-marks.k --backend haskell
kast --backend haskell fvk/mark-mro-spec.k
kprove fvk/mark-mro-spec.k
```

Expected machine-check result after installing/running K: `#Top` for the claims
above, modulo the abstraction described in `fvk/SPEC.md`.

## Symbolic proof sketch

Let `Own(C)` be the normalized marks from `C.__dict__["pytestmark"]`, or empty
if the class has no direct `pytestmark`. Let `Names(L)` be the marker-name set of
a normalized mark list `L`.

For the issue shape:

```text
MRO(TestDings) = [TestDings, Foo, Bar, Base, object]
Own(Foo) = [foo]
Own(Bar) = [bar]
Own(TestDings) = Own(Base) = Own(object) = []
```

Pre-fix lookup:

```text
getattr(TestDings, "pytestmark", []) = Foo.pytestmark
Names(result) = {foo}
```

V1 lookup:

```text
get_unpacked_marks(TestDings)
= normalize(flatten(Own(object), Own(Base), Own(Bar), Own(Foo), Own(TestDings)))
= normalize([bar, foo])
Names(result) = {bar, foo}
```

Therefore both required marker names are visible. The proof does not rely on the
list order `[bar, foo]`; it discharges the public issue's completeness property.

For storage:

```text
Own(Base) = [a]
store_mark(Sub, b)
  direct = get_unpacked_marks(Sub, consider_mro=False)
         = Own(Sub)
         = []
  Sub.pytestmark := [b]

Later lookup:
  get_unpacked_marks(Sub) = flatten(Own(Base), Own(Sub)) = [a, b]
```

If `store_mark` used the MRO-expanded view, `Sub.pytestmark` would become
`[a, b]`, and later lookup would see `[a]` from `Base` plus `[a, b]` from `Sub`.
The `consider_mro=False` side condition is therefore necessary.

For non-class objects, V1 executes the original branch:

```text
mark_list = getattr(obj, "pytestmark", [])
if not isinstance(mark_list, list):
    mark_list = [mark_list]
return normalize_mark_list(mark_list)
```

For invalid marks, every path still calls `normalize_mark_list`, whose existing
type check raises `TypeError` for non-`Mark` entries.

## Adequacy gate

The English claims in `fvk/FORMAL_SPEC_ENGLISH.md` match the required public
intent in `fvk/INTENT_SPEC.md` for completeness, no sibling bleed, non-class
frame behavior, and invalid mark handling. The audit intentionally does not
claim a settled sibling-base order policy; that is recorded as Finding F3.

## Test guidance

No tests were run, and no tests were edited.

Recommended tests to keep or add, conditioned on normal project workflow:

- Keep existing inheritance and no-sibling-bleed marker tests.
- Add a multiple-inheritance class marker test that asserts both marker names.
- Add an order-sensitive test only after maintainers choose a class-MRO order
  policy.

No test should be removed based on this constructed proof until the emitted K
commands have been run and returned `#Top`.
