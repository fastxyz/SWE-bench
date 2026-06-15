# Baseline Notes

## Root cause

`SplitArrayWidget.get_context()` builds one `final_attrs` dictionary and passes it to each child widget while rendering the array entries. `CheckboxInput.get_context()` added `attrs['checked'] = True` directly to the dictionary it received when the current value should be checked. After the first true value in a split boolean array, that mutation remained in `final_attrs`, so later checkbox subwidgets inherited `checked` even when their values were false.

## Changed files

`repo/django/forms/widgets.py`

`CheckboxInput.get_context()` now copies a non-`None` `attrs` dictionary before adding the generated `checked` attribute. This keeps the rendered checkbox behavior unchanged while preventing caller-owned attrs from being mutated and reused by later widgets.

## Assumptions and alternatives

I assumed `attrs` passed to widget `get_context()` should be treated as caller-owned input. That matches the base widget behavior, where `Widget.get_context()` builds a merged attrs dictionary for the returned context rather than mutating the extra attrs argument.

I considered changing only `SplitArrayWidget` to pass a fresh attrs dictionary to each subwidget. That would fix the reported reproduction, but it would leave `CheckboxInput.get_context()` as the only widget mutating caller-provided attrs and could allow the same leak in any other composite widget or custom rendering path that reuses attrs. Copying in `CheckboxInput` addresses the mutation at its source.

I did not modify tests because this benchmark requires source-only changes and a fixed hidden test suite.
