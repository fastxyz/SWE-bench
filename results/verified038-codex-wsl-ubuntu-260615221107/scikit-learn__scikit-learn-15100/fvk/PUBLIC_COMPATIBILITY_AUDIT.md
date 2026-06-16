# Public Compatibility Audit

Changed public symbol: `sklearn.feature_extraction.text.strip_accents_unicode`.

## Signature

Before and after V1, the helper accepts one argument, `s`. No new parameters, return type changes, or exception policy changes were introduced.

Status: compatible. Traces to O-7.

## Public Exports

`strip_accents_unicode` remains in `__all__`.

Status: compatible. Traces to O-7.

## Call Sites

`build_preprocessor` still maps `strip_accents == 'unicode'` to `strip_accents_unicode`.

Status: compatible. Traces to O-7.

## Subclasses and Overrides

No virtual method signature or dispatch shape was changed by V1. The fix is internal to the helper body.

Status: no unhandled override risk found.

