# Public Evidence Ledger

| ID | Source | Quoted evidence | Semantic obligation |
|---|---|---|---|
| E1 | `benchmark/PROBLEM.md` | "place the signatures for each of the overloaded C++ methods at the start of the docstring" | Leading docstring signatures form the overload family. |
| E2 | `benchmark/PROBLEM.md` | "`autodoc_docstring_signature` can only pick up the first one" | Current first-only extraction is the defect. |
| E3 | `benchmark/PROBLEM.md` | "pick up all of them" | Extract every leading overload signature. |
| E4 | `benchmark/PROBLEM.md` | "`getFeatures` has 4 overloaded signatures" | Cardinality N must be preserved, not hard-coded to two. |
| E5 | `repo/doc/usage/extensions/autodoc.rst` | "put the signature into the first line of the function's docstring" | Existing N=1 behavior and leading-only placement are public behavior. |
| E6 | `repo/sphinx/ext/autodoc/__init__.py` | `py_ext_sig_re` and `base not in valid_names` | Accepted signature syntax and name matching are implementation facts used in the semantics. |
| E7 | `repo/sphinx/ext/autodoc/__init__.py` | `sig.split("\n")` in `add_directive_header()` | Newline-separated signature strings are an existing rendering protocol. |
| E8 | `repo/sphinx/ext/autodoc/__init__.py` | `DocstringStripSignatureMixin` discards `_args` | Strip-only documenters are compatibility consumers of `_find_signature()`. |
