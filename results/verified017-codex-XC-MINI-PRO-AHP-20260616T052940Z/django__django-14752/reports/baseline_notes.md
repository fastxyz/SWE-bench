# Baseline Notes

## Root Cause

`django.contrib.admin.views.autocomplete.AutocompleteJsonView.get()` built each autocomplete result dictionary inline inside the `JsonResponse` payload. Because that conversion was not factored into a method, subclasses that needed to add extra per-result fields had to override the entire `get()` method, duplicating request processing, permission checks, queryset handling, pagination handling, and response construction.

## Changed Files

`repo/django/contrib/admin/views/autocomplete.py`

Extracted the default result serialization into `AutocompleteJsonView.serialize_result(obj, to_field_name)` and changed `get()` to call that method for each object in `context['object_list']`. The default implementation returns the same dictionary as before, `{'id': str(getattr(obj, to_field_name)), 'text': str(obj)}`, so existing autocomplete responses keep the same shape while subclasses can override just the per-result serialization.

## Assumptions and Alternatives

I assumed the requested extension point should be on `AutocompleteJsonView` itself, matching the issue's proposed API and keeping customization near the existing response code.

I considered adding a hook that receives the request, context, or full result list, but rejected that because the issue only needs per-object customization and a broader hook would increase the API surface without being necessary for the described use case.

I also considered changing admin widgets or `ModelAdmin` APIs, but rejected that because the limitation is specifically caused by the inline serialization in `AutocompleteJsonView.get()`.

No tests were run because the task instructions explicitly prohibit running tests or project code in this session.
