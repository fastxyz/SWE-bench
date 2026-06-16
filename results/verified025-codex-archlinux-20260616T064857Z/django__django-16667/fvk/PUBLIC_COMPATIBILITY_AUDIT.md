# Public Compatibility Audit

Status: pass.

Changed public symbol: `django.forms.widgets.SelectDateWidget.value_from_datadict`.

## Signature

Before and after:

```python
def value_from_datadict(self, data, files, name):
```

No signature change.

## Callers and Overrides

Observed public/internal call path:

- `django.forms.forms.BoundField` / form binding obtains widget data through `widget.value_from_datadict(self.data, self.files, html_name)`.
- `django.contrib.admin.widgets.RelatedFieldWidgetWrapper.value_from_datadict()` delegates to the wrapped widget with the same arguments.
- Public tests instantiate `SelectDateWidget` directly and call `value_from_datadict(data, {}, "field")`.

No caller needs an argument, return-shape, or exception-protocol update. The only behavior change is that an input that previously raised an uncaught `OverflowError` now follows the existing invalid-date return path.

## Return Categories

Preserved categories:

- `None` for all-empty split components.
- formatted date string for valid complete triples.
- pseudo-ISO invalid string for invalid complete triples.
- `data.get(name)` fallback for missing component data.

Newly covered category:

- oversized complete triples now return the pseudo-ISO invalid string instead of raising `OverflowError`.

