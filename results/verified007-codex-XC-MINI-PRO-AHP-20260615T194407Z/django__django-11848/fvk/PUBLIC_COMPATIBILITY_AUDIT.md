# Public Compatibility Audit

Status: constructed for FVK audit, not machine-checked.

## Changed public symbol

`django.utils.http.parse_http_date(date)`

The signature is unchanged. The return type remains an integer UTC epoch
timestamp for valid dates. Invalid syntax or invalid date fields still raise
`ValueError` through the existing exception wrapper.

## Related public symbol

`django.utils.http.parse_http_date_safe(date)`

The signature is unchanged. It still delegates to `parse_http_date()` and
returns `None` if parsing raises.

## Public callsites searched

- `django.middleware.http.ConditionalGetMiddleware.process_response()`
- `django.utils.cache.get_conditional_response()`
- `django.views.static.was_modified_since()`

These callsites consume either an integer timestamp or the safe wrapper's
`None`. The V1 change does not alter dispatch, arguments, exception classes
observed by callers, or return shape.

## Compatibility conclusion

Passed. The only intended observable change is the timestamp value for parsed
years below 100 whose current-century candidate is more than 50 years in the
future. That is the public issue's requested behavior change.

