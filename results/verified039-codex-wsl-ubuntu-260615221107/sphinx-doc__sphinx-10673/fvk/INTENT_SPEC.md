# Intent Spec

Status: constructed from public intent only; not machine-checked.

## Required behavior

1. A toctree containing the bare entries `genindex`, `modindex`, and `search`
   must not emit "toctree contains reference to nonexisting document" warnings.
2. Those entries denote Sphinx generated pages, not source documents. They
   should be stored as link entries and must not be added to `includefiles`.
3. `modindex` must use the existing standard-domain label target
   `py-modindex`, matching `:ref:`modindex`` behavior.
4. Normal toctree document behavior must be preserved. If an entry resolves to
   an existing source document, it remains a source document entry; unknown
   non-generated entries still warn.
5. Downstream toctree consumers must not treat generated-page entries as source
   doctrees for section numbering, figure numbering, rebuild dependencies, or
   relation construction.

## Domain

The verified domain is a Sphinx environment with the standard domain installed
and its built-in labels for `genindex`, `modindex`, and `search` available. The
direct entries are the issue's generated-page labels, optionally with a leading
slash normalized away by the parser. This audit covers partial correctness of
the parsing and resolving paths; it does not prove termination or full Python
semantics.

