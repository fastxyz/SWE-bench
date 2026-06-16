# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public intent, source inspection, and proof-obligation construction; no tests or K tooling were run.

## F-1: V1 fixed the reported simple variable case

* Classification: confirmed behavior against intent.
* Evidence: issue input `_foo = None  #: :meta public:` under `automodule :members:`.
* V1/V2 path: parser stores the comment in `attr_docs`; `filter_members()` now extracts metadata from `attr_doc`; `public` makes `isprivate = False`; the documented-attribute branch keeps the member and sets `isattr = True`.
* Input -> observed vs expected: `_foo = None  #: :meta public:` -> V1/V2 keeps `_foo`; expected `_foo` shown.
* Related obligations: PO-1, PO-2, PO-4.

## F-2: V1 did not give attribute-comment visibility precedence over conflicting runtime docstring metadata

* Classification: code bug in V1, fixed in V2.
* Evidence: `Documenter.add_content()` uses `attr_docs` as the attribute's documentation content, so a variable's source attribute comment is the effective documentation source for that variable.
* V1 input -> observed vs expected: a private-looking variable whose assigned runtime object has docstring metadata `:meta private:` and whose source attribute comment has `#: :meta public:` -> V1 merged both markers, the existing `private` check won, and the variable was skipped; expected the explicit variable attribute documentation to make it public.
* V2 change: `repo/sphinx/ext/autodoc/__init__.py:735` through `repo/sphinx/ext/autodoc/__init__.py:739` now use attribute-comment metadata as the effective metadata source when it contains `private` or `public`.
* Related obligations: PO-3, PO-6.

## F-3: No machine check or runtime test was possible in this session

* Classification: proof/test gap, not a code bug.
* Evidence: task forbids tests, Python execution, and K tooling.
* Expected follow-up: when an execution environment exists, run the recorded `kompile`/`kast`/`kprove` commands and the project test suite. Do not remove tests based on the constructed proof alone.
* Related obligations: PO-7.

## Proof-derived findings from `/verify`

The constructed proof produced one actionable finding, F-2, and V2 addresses it. No remaining proof obligation requires another source change within the public issue scope.
