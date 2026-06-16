# Iteration Guidance

Status: V1 confirmed as V2.

## Decision

No additional production-code edit is justified by the FVK audit.

The V1 change in `repo/django/forms/widgets.py` is minimal and directly discharges F-001 through PO-001:

```python
except (ValueError, OverflowError):
```

The preservation obligations PO-002 through PO-006 show that broadening the existing invalid-date handler to include `OverflowError` does not alter the valid-date path, the all-empty path, the missing-component fallback, the pseudo-ISO representation, or the public caller protocol.

## Rejected Follow-up Changes

- Catching `TypeError`: rejected for this issue because the public domain is request `GET` or `POST` string data, and no public evidence requires arbitrary object values to be accepted.
- Pre-validating integer ranges: rejected because it duplicates Python date validation and is broader than needed to discharge PO-001.
- Returning `None` for overflow: rejected because it would violate PO-002's preservation of invalid complete triples as pseudo-ISO values.
- Clamping oversized values: rejected because it would convert invalid submitted data into a different date value rather than preserving invalid input for validation.

## Recommended Tests

Do not edit tests in this benchmark. In a normal Django development pass, add a regression test asserting that an oversized complete triple returns a pseudo-ISO invalid value or makes a `DateField` form invalid without raising. Keep integration tests around form validation and rendering.

## Verification Follow-up

The proof remains constructed, not machine-checked. Future verification should run:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell select-date-widget-spec.k
kprove select-date-widget-spec.k
```

Until `kprove` returns `#Top`, do not remove tests based on proof redundancy.

