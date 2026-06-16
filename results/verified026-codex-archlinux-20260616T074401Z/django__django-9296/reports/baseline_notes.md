# Baseline Notes

## Root cause

`django.core.paginator.Paginator` exposed `page_range` for callers that wanted to loop over page numbers, and exposed `page(number)` for obtaining each `Page`, but the `Paginator` object itself did not implement Python's iteration protocol. As a result, `for page in paginator` was not supported even though the class already had all the data and behavior required to produce pages in order.

## Files changed

* `repo/django/core/paginator.py`
  * Added `Paginator.__iter__()`.
  * The method iterates over `self.page_range` and yields `self.page(page_number)` for each page number.
  * Delegating to `page_range` preserves existing `num_pages`, orphan, and `allow_empty_first_page` behavior.
  * Delegating to `page()` preserves existing page number validation, slicing behavior, and the `_get_page()` subclass customization hook.

## Assumptions and rejected alternatives

* I assumed iteration should yield `Page` instances, not page numbers, because the issue's proposed implementation yields `self.page(page_num)` and because callers can already iterate `page_range` when they need numbers.
* I assumed an empty paginator with `allow_empty_first_page=False` should yield no pages because `page_range` is already empty in that case.
* I assumed an empty paginator with `allow_empty_first_page=True` should yield the existing empty first page because `page_range` already contains page 1 and `page(1)` is valid in that configuration.
* I rejected changing `page_range` or making `Paginator` inherit from a sequence type because the requested behavior only requires the iterable protocol and broader changes would affect more of the public API.
* I did not modify tests or run code, in line with the benchmark instructions.
