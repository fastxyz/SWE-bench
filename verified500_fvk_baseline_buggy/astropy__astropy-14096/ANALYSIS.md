# astropy__astropy-14096 — FVK analysis

- **Verdict:** B_COMPLETENESS — baseline truncates its subclass-property MRO scan at `SkyCoord` (`if cls is SkyCoord: break`), so a custom property inherited from a mixin ordered *after* SkyCoord still produces the misleading "no attribute" message; fvk (like gold) scans the full MRO and reports the real missing inner attribute.
- **Pitch-worthiness (1-5):** 4

## The issue
Subclassing `SkyCoord` and adding a `@property` that internally accesses a missing attribute produced a misleading error: `AttributeError: 'C' object has no attribute 'prop'` (blaming the property itself) instead of naming the real missing attribute the property tried to read. The fix should surface the inner attribute error.

## What baseline did
Baseline added an MRO walk to detect subclass-defined properties, but **breaks the loop the moment it reaches `SkyCoord`**:
```python
for cls in self.__class__.__mro__:
    if cls is SkyCoord:
        break          # <-- stops scanning here
    if attr in cls.__dict__:
        ...
```
For `class C(SkyCoord, Mixin)` the MRO is `[C, SkyCoord, ..., Mixin, object]`, so a property defined on `Mixin` (after SkyCoord) is **never seen** → the misleading message returns. It also executes the property twice.

## What fvk changed and why
fvk scans the full MRO for the first provider of the attribute and intercepts if that provider is outside `SkyCoord.__mro__` — matching gold's behavior (gold delegates to `__getattribute__`, which naturally honors the full MRO) — and executes the property only once.

## Concrete demonstration (executed)
```python
class Mixin:
    @property
    def prop(self):
        return self.random_attr        # attribute that doesn't exist
class C(SkyCoord, Mixin):
    pass
C(...).prop
```
| variant | error |
|---|---|
| **baseline** | `AttributeError: 'C' object has no attribute 'prop'`  ← misleading (the exact bug) |
| **fvk / gold** | `AttributeError: ... 'random_attr'`  ✅ names the real cause |

`class C(SkyCoord, Mixin)` (primary base first) is a normal, common inheritance layout — not contrived.

## Why the tests missed it
The FAIL_TO_PASS test only covers the simple direct-subclass case (property on the immediate subclass, before SkyCoord in the MRO), which baseline's truncated scan does reach. No test uses a mixin ordered after SkyCoord, so baseline passes while retaining the defect.

## Gold comparison
Gold scans the full MRO (via `__getattribute__` delegation); fvk matches that behavior. Baseline's `break at SkyCoord` is the divergence. **GOLD_MATCH: yes.**

## Confidence & caveats
- **High confidence:** the MRO-scan logic was reproduced verbatim from the patches and executed; baseline yields the misleading message, fvk/gold the correct one.
- The double-execution-of-property difference is a secondary correctness nicety (matters only if the property has side effects).
