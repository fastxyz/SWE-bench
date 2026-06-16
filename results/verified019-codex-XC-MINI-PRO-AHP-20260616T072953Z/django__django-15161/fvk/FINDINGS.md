# FINDINGS

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F-001: V1 discharges the reported verbose-path defect

Classification: confirmed code fix.

Input: exact instances of root-exported, deconstructible expression classes,
for example `Value("name")`, `Case(...)`, `When(...)`,
`ExpressionWrapper(...)`, or `OrderBy(...)`.

Observed before V1: inherited/default deconstruction returned paths in
`django.db.models.expressions`, e.g. `django.db.models.expressions.Value`.

Expected from public intent: the same simplification already applied to `F`,
namely `django.db.models.<ClassName>`, so migration serialization can emit
`models.<ClassName>` under `from django.db import models`.

V1 result by inspection: `repo/django/db/models/expressions.py` now gives each
in-domain exact class an explicit `@deconstructible(path='django.db.models.X')`
decorator. This satisfies PO-1, PO-2, and PO-5.

## F-002: Exact-type guard prevents unintended subclass/path broadening

Classification: compatibility confirmation.

Input: a subclass or internal helper inheriting a deconstruct method, such as
`RawSQL` through `Expression`, or a custom user subclass of `Value`.

Observed/expected: `deconstructible.deconstruct()` uses the custom `path` only
when `type(obj) is klass`; otherwise it returns the object's actual module path.

V1 result by inspection: adding custom paths to public classes does not force
their subclasses or internal helpers to deconstruct to `django.db.models.X`.
This satisfies PO-3, PO-4, and PO-7.

## F-003: `Subquery` and `Exists` remain intentionally out of scope

Classification: confirmed boundary with residual ambiguity.

Input: exact `Subquery(...)` or `Exists(...)` instances.

Observed in source: both classes are exported from `django.db.models`, but they
do not currently define or inherit `deconstruct()`. `Subquery` stores a query
object derived from a queryset, which is not established by the issue as a
migration-serializable constructor argument.

Expected from public intent: simplify paths for expressions that already
deconstruct like `F`; the issue does not require adding new deconstruction
support for query-bearing expressions.

V1 result by inspection: V1 does not add decorators to `Subquery` or `Exists`.
This satisfies PO-6. Residual risk: if future public requirements explicitly
say these classes must become migration-deconstructible, that is a separate
feature and should include query serialization semantics.

## F-004: Legacy expectations for long expression paths are SUSPECT

Classification: stale-test/legacy-behavior signal.

Input: any assertion expecting `django.db.models.expressions.Value` or another
long path for an exact class that is also importable from `django.db.models`.

Observed legacy behavior: long module paths.

Expected from public intent: short `django.db.models.<ClassName>` paths.

Conclusion: such expectations conflict with the public issue and should not
veto the fix. This supports PO-1 and PO-8. No test files were modified.

## F-005: Proof and validation are constructed, not machine-checked

Classification: proof capability / process limitation.

No tests, Python, `kompile`, `kast`, or `kprove` were run. The proof artifacts
state the commands that would machine-check the model, but their expected
success is reasoned about only. This does not change the code conclusion, but
test removal or machine-verified confidence must remain conditional on actually
running the emitted commands in a suitable environment.

