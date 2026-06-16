# Intent Spec

Source: `benchmark/PROBLEM.md`.

1. Type aliases documented by next-line triple-quoted docstrings should display
   those docstrings in autodoc output.
2. The behavior should be consistent across all aliases in the reported family:
   `Dict[...]`, `Union[...]`, and `Callable[...]`.
3. For documented aliases, generated `alias of ...` fallback text is not the
   expected replacement content.
4. Fallback text remains acceptable for aliases with no explicit source
   docstring-comment.
5. Source files used by autodoc to produce content should be rebuild
   dependencies, matching existing autodoc analyzer behavior.
