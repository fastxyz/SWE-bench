# Baseline Notes

## Root cause

`ModuleDocumenter.import_object()` stores the module's `__all__` value in
`self.__all__`. A missing `__all__`, an ignored `__all__`, or an invalid
`__all__` leaves that value as `None`; a valid empty export list is stored as
an empty list or tuple.

`ModuleDocumenter.get_object_members()` used `if not self.__all__:` when
autodoc was asked for all module members. That truthiness check treated a valid
empty `__all__` the same as no `__all__` at all, so autodoc returned all module
members and applied only the normal imported-member filtering. As a result,
modules with `__all__ = []` still documented functions such as `foo`, `bar`,
and `baz`.

## Files changed

`repo/sphinx/ext/autodoc/__init__.py`

Changed the module-member selection branch from `if not self.__all__:` to
`if self.__all__ is None:`. Now only an absent or ignored `__all__` uses the
implicit-member path. Any explicit valid sequence, including an empty list or
tuple, uses the existing `__all__` filtering path. For an empty sequence, every
module member is marked skipped and the existing common filter omits them.

## Assumptions and alternatives considered

I assumed `inspect.getall()` is already responsible for distinguishing absent
or invalid `__all__` from valid sequences. It returns `None` only when the
module has no `__all__`, and returns the sequence unchanged for valid lists and
tuples, so no change was needed there.

I considered adding a special case that immediately returns an empty member
list for `__all__ = []`. I rejected that because the existing non-empty
`__all__` path already marks non-exported members as skipped and routes them
through the normal autodoc filtering and event hooks. Reusing that path keeps
the behavior consistent for all explicit `__all__` values.

I also left `sort_members()` unchanged. Its `if order == 'bysource' and
self.__all__:` condition only affects ordering when there are exported names to
sort by; an empty export list produces no documented members through the fixed
selection path.
