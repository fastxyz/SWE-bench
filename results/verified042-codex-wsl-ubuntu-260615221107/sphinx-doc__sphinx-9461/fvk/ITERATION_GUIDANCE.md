# FVK Iteration Guidance

Status: constructed guidance; no tests or code were executed.

## Decision

Keep the V1 architecture and apply one narrow V2 improvement:

- Use `get_class_member(subject, name, safe_getattr)` in
  `get_object_members()`' enum-specific class-member branch.

This aligns the generic enum branch with the proof obligation that all audited
class-member lookup paths preserve `classmethod(property(...))` as a property
object.

## Next Code Iteration

No further production-code changes are justified by the current public intent.
The issue's named class-property paths are covered by the helper and by
`PropertyDocumenter.import_object()`.

Do not add a `:classmethod:` option to `py:property`; the Python domain property
directive does not define that option, and ordinary Sphinx property
documentation is the intended reuse path.

Do not change autosummary module scanning in this iteration. The public issue
concerns class members, and autosummary class generation consumes
`get_class_members()`, which is covered.

## Suggested Tests For A Future Executable Environment

These are recommendations only; test files were not modified.

- A class with `@classmethod @property` appears in `autoclass :members:` output.
- The generated directive is `py:property` and includes the getter docstring.
- An abstract class property emits `:abstractmethod:`.
- A subclass override of a base class property is preserved.
- Autosummary generated class pages include the member.
- An enum class with a directly defined class property follows the helper path.

## Questions For A Broader Intent Pass

If future public evidence says metaclass attributes should appear as documented
members of ordinary classes, extend the specification to include lookup through
`type(subject).__mro__`. The current issue names class properties defined on the
documented classes themselves, including a metaclass class's own members, so that
broader rule is not required here.

## Verification Follow-Up

When an execution environment exists, run the project test suite and, if a real
K encoding is added, run:

```sh
kompile fvk/mini-python-autodoc.k --backend haskell
kast --backend haskell fvk/autodoc-class-property-spec.k
kprove fvk/autodoc-class-property-spec.k
```

Until then, the proof remains constructed, not machine-checked.
