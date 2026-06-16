# Baseline Notes

## Root cause

Autodoc renders inherited bases with `restify()` over the class object's base list. For classes that inherit from a mocked object, Python preserves the original base expression in `__orig_bases__`; that original base is a `_MockObject` instance rather than the temporary mock class returned by `__mro_entries__()`.

Mock instances previously set `__qualname__` to the empty string in `_MockObject.__init__()`. When autodoc used `__orig_bases__`, `restify()` saw the instance's mocked `__module__` such as `torch.nn` plus the empty `__qualname__`, producing `torch.nn.` instead of `torch.nn.Module`.

## Files changed

`repo/sphinx/ext/autodoc/mock.py`

Changed `_MockObject.__init__()` so each mock instance exposes the qualified name of its generated mock class. A mocked object such as `torch.nn.Module` now has `__module__ == "torch.nn"` and `__qualname__ == "Module"`, so the existing autodoc inheritance rendering path produces the complete base class name.

## Assumptions and alternatives

I assumed the correct display name is the mocked object's module plus its short generated class name, matching how `_make_subclass()` already constructs mock classes.

I considered changing `ClassDocumenter.add_directive_header()` to replace mocked `__orig_bases__` entries with their resolved classes before calling `restify()`. I rejected that as too localized: the bad metadata comes from the mock object itself, and fixing the metadata also keeps other `restify()` users from seeing a blank qualified name.

I considered adding a mock-specific branch to `sphinx.util.typing.restify()` using `__display_name__`. I rejected that because `restify()` is a general typing utility, while the incorrect empty `__qualname__` is created in autodoc's mock implementation.

No tests or executable code were run, per the task instructions.
