# INTENT SPEC

Status: constructed, not machine-checked.

Public intent requires generated migration code for deconstructible expressions
that are importable from `django.db.models` to use the simplified
`django.db.models.<ClassName>` path, following the already accepted `F`
behavior.

Required behaviors:

1. Exact deconstruction of comparable root-exported expression classes returns
   `django.db.models.<ClassName>`.
2. Constructor args and kwargs returned by `deconstruct()` are unchanged.
3. The simplification should enable migration serialization as
   `models.<ClassName>` under `from django.db import models`.
4. Behavior outside expression deconstruction paths is preserved.
5. Public intent does not require making expressions deconstructible if they did
   not already expose a deconstruction contract.

