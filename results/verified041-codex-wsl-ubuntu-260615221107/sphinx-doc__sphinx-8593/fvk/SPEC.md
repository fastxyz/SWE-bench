# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the visibility decision for autodoc members in `Documenter.filter_members()` as it applies to module variables documented by source attribute comments. The proof target is the observable decision pair:

* `keep`: whether the member survives filtering.
* `isattr`: whether the member is handed to attribute/data documenters.

The model covers the normal issue setup: `.. automodule:: example` with `:members:`, no user `autodoc-skip-member` override, no `:exclude-members:`, no special `__dunder__` target, and no `:private-members:` admission unless explicitly modeled. Those exclusions are frame conditions because the public issue states only `sphinx.ext.autodoc` and no extra tools.

## Public Intent Ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

* E1/E2: The issue requires `_foo = None  #: :meta public:` to be shown by `automodule :members:`.
* E3/E4: The docs define `:meta private:` and `:meta public:` as visibility metadata.
* E5: `repo/sphinx/pycode/parser.py:271` and `repo/sphinx/pycode/parser.py:353` already store variable comments; `repo/sphinx/pycode/__init__.py:170` exposes them as `attr_docs`.
* E6: `repo/sphinx/ext/autodoc/__init__.py:599` uses `attr_docs` as attribute documentation content.
* E7: `repo/sphinx/ext/autodoc/__init__.py:751` through `repo/sphinx/ext/autodoc/__init__.py:777` define the branch order and the `isattr = True` attribute branch.

## Formal Domain

Inputs to `mini-autodoc.k` abstract the relevant state:

* `NamePrivate`: whether `membername.startswith('_')`.
* `DocMeta`: visibility metadata extracted from the runtime docstring.
* `AttrPresent`: whether `(namespace, membername)` is present in `attr_docs`.
* `AttrMeta`: visibility metadata extracted from that attribute documentation.
* `WantAll`: `automodule :members:` all-members mode.
* `PrivateAllowed`: whether `:private-members:` admits this member.
* `Excluded`, `Special`, `SpecialAllowed`, `HasDoc`, `UndocMembers`, `Mocked`, `Skipped`: earlier branch/frame inputs from `filter_members()`.

## Claims

The K claims are in `fvk/autodoc-filter-spec.k`.

* `META-PUBLIC-VARIABLE`: private-looking variable plus attribute-comment `public` metadata yields `decision(true, true)`.
* `META-PRIVATE-VARIABLE`: public-looking variable plus attribute-comment `private` metadata yields `decision(false, true)` when private members are not admitted.
* `ATTR-VISIBILITY-PRECEDENCE`: attribute-comment `public` metadata overrides conflicting runtime-docstring `private` metadata for variable documentation.
* `DOCSTRING-PUBLIC-FRAME`: runtime-docstring `public` metadata remains effective when the attribute documentation has no visibility marker.

## Source Decision

V1 fixed the reported `_foo = None  #: :meta public:` case but did not discharge `ATTR-VISIBILITY-PRECEDENCE`. V2 changes `repo/sphinx/ext/autodoc/__init__.py:733` through `repo/sphinx/ext/autodoc/__init__.py:739` so visibility markers found in `attr_doc` become the effective metadata source for that member; when `attr_doc` has no visibility marker, runtime-docstring metadata is preserved.
