# FORMAL SPEC ENGLISH

Status: constructed, not machine-checked.

Claim family `SHORT-PATH-*`: For every listed root-exported expression class
with a custom root path, exact deconstruction returns the custom path
`django.db.models.<ClassName>` and returns the same captured args and kwargs.

Claim `INTERNAL-FALLBACK-RAWSQL`: If an object uses an inherited deconstruct
closure but is not the exact decorated class, deconstruction returns the
object's actual module path, not the inherited class's custom root path.

Claim `NO-SUBQUERY-CONTRACT`: If a class has no installed deconstruct closure,
this model does not assign it a deconstruction result. This mirrors V1's
decision not to add new deconstructibility to `Subquery` or `Exists`.

Serializer consequence: A returned path whose module is `django.db.models`
serializes to `models.<ClassName>` with `from django.db import models`.

