# Intent Spec

Status: constructed from public evidence only; not machine-checked.

## Intended behavior

1. Under `sphinx.ext.autodoc`, `.. automodule:: example` with `:members:` should include a module variable named `_foo` when `_foo` has source attribute documentation containing `:meta public:`.

2. Autodoc visibility metadata is a member visibility override:
   * `:meta public:` makes an otherwise private-looking member public.
   * `:meta private:` makes an otherwise public-looking member private.
   * If both markers are present in the same effective metadata source, the existing autodoc rule checks `private` first.

3. Source attribute comments (`#:` comments attached to assignments) are the documentation source for documented variables. Therefore visibility metadata in that attribute documentation must participate in the same visibility decision as metadata in runtime docstrings.

4. In the normal issue setup, no user `autodoc-skip-member` handler, `:exclude-members:`, `:special-members:`, or `:private-members:` option changes the result.

5. Existing autodoc frame behavior must be preserved outside the metadata visibility decision: mocked members remain skipped, excluded members remain skipped, special-member filtering remains before attribute filtering, and documented attributes still set `isattr = True`.

## Observed V1 behavior to audit

V1 merged metadata from `attr_docs` into the runtime-docstring metadata dictionary. It fixed the issue example but did not give attribute-comment visibility markers precedence over conflicting runtime-docstring markers from the assigned value.
