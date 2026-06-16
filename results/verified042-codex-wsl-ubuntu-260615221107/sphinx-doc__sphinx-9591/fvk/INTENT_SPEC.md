# Intent Spec

Constructed, not machine-checked.

## Public Intent

1. Property return annotations documented by autodoc must be rendered as type
   annotations that can resolve to Python cross-references.
2. The issue example `@property def end(self) -> Point` requires the displayed
   `Point` type in the property signature to be represented as a Python
   reference target, not plain inert text.
3. Attribute annotations already cross-reference documented classes; property
   type annotations should have the same annotation-parsing behavior.
4. The fix must not change how autodoc discovers property return annotations,
   the public `PyProperty.handle_signature(sig, signode)` signature, or the
   behavior of properties without a `:type:` option.

## Domain

The in-scope path is the Python domain handling of a `py:property` directive
that has an optional `:type:` option. The proof models a non-empty annotation
string representing a documented type name such as `Point`; this is the exact
class-name case shown in the issue. More complex annotation syntax is covered by
the existing `_parse_annotation()` helper and is framed as reuse of the same
parser already used by attributes and variables.

## Out Of Scope

The FVK proof does not model the full docutils node implementation, HTML writer,
or Python AST parser internals. Those are trusted project mechanisms already
used by variable, attribute, parameter, and return annotation paths. The proof
keeps the observable property that matters for this issue: whether the type
token is represented as a pending Python cross-reference node or as plain text.
