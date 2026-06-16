# PROOF

Status: constructed, not machine-checked. No tests, Python, `kompile`,
`kast`, or `kprove` were run.

## Statement

For every in-domain exact expression class `C`, deconstruction returns the
short path `django.db.models.C` while preserving constructor arguments and
keyword arguments. For non-exact classes and internal helpers, fallback module
paths are preserved.

## Formal Claims

The formal claims are in `fvk/deconstructible-expressions-spec.k` and use the
small semantics in `fvk/mini-python-deconstruct.k`.

The core claim schema is:

`deconstruct(C, C, A, K) => tuple(rootPath(C), A, K)`

when `C` has a custom root path, plus a fallback claim:

`deconstruct(Owner, ObjClass, A, K) => tuple(modulePath(ObjClass), A, K)`

when `ObjClass` is not the exact decorated class.

## Constructed Proof Sketch

1. `deconstructible(path=P)` installs a generated `deconstruct(obj)` closure on
   the decorated class.
2. In the generated closure, the first branch checks `if path and type(obj) is
   klass`.
3. For an exact instance of a V1-decorated class `C`, the branch condition is
   true because `path` is `django.db.models.C` and `type(obj) is C`.
4. The branch computes `module_name, _, name = path.rpartition('.')`, checks
   that `django.db.models` has attribute `C`, and returns
   `(path, obj._constructor_args[0], obj._constructor_args[1])`.
5. `django/db/models/__init__.py` exports each target class, so the import
   check is satisfied for every class in PO-1.
6. The returned args and kwargs are exactly the captured constructor args and
   kwargs; V1 does not change this code.
7. For subclasses and internal helpers, `type(obj) is klass` is false for the
   inherited closure's owner class, so the fallback branch returns
   `obj.__class__.__module__ + "." + obj.__class__.__name__`.
8. `Subquery` and `Exists` are not decorated and do not inherit this generated
   method in V1, so no new deconstruction contract is introduced.
9. The migration serializer has a branch for `module == "django.db.models"`,
   so the returned root path serializes as `models.C` under
   `from django.db import models`, matching the public issue.

By transitivity of the generated-closure branch and the serializer path branch,
the source change satisfies PO-1 through PO-7 for the specified domain.

## Machine-Check Commands Not Run

The commands that would check the formal core in an environment with K are:

```sh
kompile fvk/mini-python-deconstruct.k --backend haskell
kast --backend haskell fvk/deconstructible-expressions-spec.k
kprove fvk/deconstructible-expressions-spec.k --definition fvk/mini-python-deconstruct-kompiled
```

Expected result if the mini-semantics and claims parse as intended:
`kprove` discharges the claims to `#Top`.

## Test Guidance

No tests were run or modified. If tests are added later, they should cover:

- Each PO-1 class deconstructs to `django.db.models.<ClassName>`.
- Args and kwargs are preserved, e.g. `Value("x", output_field=...)`.
- Internal helpers and subclasses still use fallback module paths.
- `Subquery`/`Exists` are not newly asserted as deconstructible unless their
  serialization contract is separately specified.

Existing tests that assert only one in-domain exact-class path would be
subsumed only after the K claims are actually machine-checked. Until then, keep
all tests.

