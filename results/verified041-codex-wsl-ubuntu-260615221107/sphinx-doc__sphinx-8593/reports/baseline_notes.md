# Baseline Notes

## Root cause

Autodoc already parses `#: ...` variable comments into `ModuleAnalyzer.attr_docs`, and `Documenter.filter_members()` already uses `attr_docs` to recognize documented attributes.  However, the public/private decision only extracted `:meta public:` and `:meta private:` from the runtime docstring (`doc`).  Module variables such as `_foo = None  #: :meta public:` usually have no useful runtime docstring, so `_foo` still fell back to the leading-underscore private-name rule and was skipped by `.. automodule:: example :members:`.

## Changed files

* `repo/sphinx/ext/autodoc/__init__.py`
  * In `Documenter.filter_members()`, look up the current member's source attribute documentation once.
  * Merge metadata extracted from that attribute documentation into the existing metadata used by the privacy decision.
  * Reuse the same lookup for the attribute-documentation branch, preserving the existing keep/skip behavior while allowing `:meta public:` and `:meta private:` in variable comments to affect it.

## Assumptions and alternatives considered

* I treated source variable comments as the relevant documentation source for module variables, because `ModuleAnalyzer` already stores them and `add_content()` already renders them as attribute documentation.
* I merged attribute-comment metadata into the same metadata dictionary used for runtime docstrings.  This preserves the existing behavior that `private` wins when both `private` and `public` markers are present.
* I considered changing the parser or module member importer, but rejected that because the parser already captures the comment and the importer already exposes documented module variables to the filter.  The missing behavior was isolated to metadata extraction during filtering.
* I did not modify tests or run code, per the task constraints.
