# Public Compatibility Audit

## Changed public symbols

`django.apps.registry.Apps.clear_cache`

- Signature before V1: `def clear_cache(self)`.
- Signature after V1: unchanged.
- Return value before V1: implicit `None`.
- Return value after V1: unchanged.
- Added behavior: calls `self.get_swappable_settings_name.cache_clear()`.
- Compatibility result: pass. The method remains callable in all existing
  in-repository callsites.

## Related cached symbol

`django.apps.registry.Apps.get_swappable_settings_name`

- Signature before V1: `def get_swappable_settings_name(self, to_string)`.
- Signature after V1: unchanged.
- Return value shape: setting name or `None`, unchanged.
- Compatibility result: pass. V1 only clears this method's cache; it does not
  change lookup semantics.

## In-repository callsites and overrides

- `ForeignObject.swappable_setting` calls
  `apps.get_swappable_settings_name(to_string)` with the same argument shape.
- App-registry mutation methods continue to call `self.clear_cache()`.
- Migration state code calls `apps.clear_cache()` after unregister/bulk update
  paths.
- Static search found no in-repository override of
  `get_swappable_settings_name()` and no changed dispatch signature.

## Compatibility conclusion

No compatibility-driven source change is required beyond V1. The fix is an
internal cache invalidation addition with no API or caller protocol change.
