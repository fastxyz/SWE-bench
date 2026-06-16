# FVK Specification: Type-Comment Imports and `unused-import`

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Scope

This FVK pass audits the production-code behavior changed for
`pylint-dev__pylint-4604`: collecting names referenced by parsed type comments
and using that collection to suppress `unused-import` when an import is used
only as a type.

The formal model intentionally covers the relevant slice:

- `_qualified_names_from_attribute`
- `VariablesChecker._store_type_annotation_node`
- the `is_type_annotation_import` decision inside `_check_imports`

The rest of `VariablesChecker` is treated as frame context.

## Public Intent Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | `benchmark/PROBLEM.md` | "unused-import false positive for a module used in a type comment" | An import referenced by a type comment must not be reported as unused. | Encoded in PO1, PO3, and K claims `REPRO-ABC` and `SUPPRESS-IMPORT`. |
| I2 | `benchmark/PROBLEM.md` | `import abc` and `X = ...  # type: abc.ABC` | A qualified attribute annotation must mark its base imported module name, here `abc`, as type-used. | Encoded in PO1 and K claim `ATTR-ABC-NAMES`. |
| I3 | `benchmark/PROBLEM.md` | `from abc import ABC` and `Y = ...  # type: ABC` | Existing simple-name type comments must keep suppressing `unused-import`. | Encoded as a frame condition in PO2. |
| I4 | `benchmark/PROBLEM.md` | "Expected behavior: `unused-import` should not be emitted." | The observable checker output must omit W0611 for imports whose `imported_name` or `as_name` appears in collected type annotation names. | Encoded in PO3 and `SUPPRESS-IMPORT`. |
| C1 | `repo/pylint/checkers/variables.py` | `_check_imports` computes `is_type_annotation_import = imported_name in self._type_annotation_names or as_name in self._type_annotation_names` | The collection must contain the same import keys `_check_imports` compares against. | Implementation evidence used for the model and PO3. |
| C2 | `repo/pylint/checkers/variables.py` | `_fix_dot_imports` can expand an unconsumed root local such as `xml` back to an imported name such as `xml.etree` | Qualified annotation collection should include dotted prefixes, not only root names, so the downstream comparison can work for dotted imports. | Proof-derived refinement in PO4. |
| C3 | `repo/tests/functional/u/unused/unused_typing_imports.py` | Existing fixtures include `List[Any]`, `typing.Optional[str]`, `defaultdict`, and function type comments | Existing simple names, subscripted annotations, and fully qualified `typing.*` annotations are public regression evidence. | Frame condition in PO2 and PO5. |

## Intent Spec

For each parsed type annotation node reachable from a type comment, Pylint must
collect the import keys represented by the annotation's referenced names.

Required cases:

- `Name("ABC")` collects `ABC`.
- `Attribute(Name("abc"), "ABC")` collects at least `abc`.
- A dotted attribute chain such as `Attribute(Attribute(Name("xml"), "etree"), "ElementTree")` collects `xml` and `xml.etree`, because `_check_imports` may compare the unconsumed import as `xml.etree`.
- `Subscript(value, args)` collects names from both the subscript value and its argument annotations, including nested attributes.
- A fully qualified `typing.*[...]` annotation must continue to collect `typing`, and must not stop collection of nested type names.

Given an import candidate `(imported_name, as_name)` and collected annotation
names `NAMES`, `_check_imports` must suppress `unused-import` exactly when
`imported_name in NAMES` or `as_name in NAMES`.

## Formal Model

The K model is in:

- `fvk/mini-pylint-variables.k`
- `fvk/type-annotation-import-spec.k`

The model abstracts astroid nodes as:

- `Name(S)`
- `Attr(BASE, FIELD)`
- `Sub(VALUE, ARGS)`
- `Other`

It abstracts `_type_annotation_names` as a mathematical set. The production code
uses a list, but only membership is observed by `_check_imports`, so set
extensionality is adequate for this property.

## Formal Spec English

Claim `ATTR-ABC-NAMES`: collecting names from `abc.ABC` yields a set containing
`abc` and `abc.ABC`.

Claim `REPRO-ABC`: after collecting `abc.ABC`, an import candidate
`import abc` is classified as type-used.

Claim `NAME-ABC`: collecting names from `ABC` yields a set containing `ABC`,
preserving the already-working `from abc import ABC` case.

Claim `TYPING-NESTED-ABC`: collecting names from
`typing.Optional[abc.ABC]` yields a set containing both `typing` and `abc`.

Claim `DOTTED-IMPORT`: collecting names from `xml.etree.ElementTree` yields a
set containing `xml.etree`, the key `_fix_dot_imports` can pass to
`_check_imports` for `import xml.etree`.

Claim `SUPPRESS-IMPORT`: for every import candidate, if its imported name or
alias is in collected annotation names, `unused-import` is not emitted for that
candidate through the type-annotation branch.

Claim `UNMATCHED-IMPORT-FRAME`: if neither imported name nor alias is in the
collected names, this fix does not suppress `unused-import`; other existing
filters remain outside this model.

## Spec Audit

| Claim | Adequacy result | Reason |
| --- | --- | --- |
| `ATTR-ABC-NAMES` | Pass | Directly matches the public repro `abc.ABC`. |
| `REPRO-ABC` | Pass | Directly matches the expected absence of W0611 for `import abc`. |
| `NAME-ABC` | Pass | Preserves the public repro's existing `ABC` behavior. |
| `TYPING-NESTED-ABC` | Pass | Follows the full-intent rule: a module used in a type comment remains used when nested under a `typing.*` type expression. |
| `DOTTED-IMPORT` | Pass | Follows from implementation evidence C2: `_check_imports` may compare dotted import keys. |
| `SUPPRESS-IMPORT` | Pass | Mirrors the existing production predicate in `_check_imports`. |
| `UNMATCHED-IMPORT-FRAME` | Pass | Prevents over-claiming; unmatched imports are left to the existing checker behavior. |

No claim relies on hidden tests, upstream fixes, evaluator output, or internet
access.

## Public Compatibility Audit

No public checker API, message symbol, method signature, return type, or
configuration option changed.

Changed production symbols:

- Added private helper `_qualified_names_from_attribute(attribute)`.
- Extended private helper behavior in `_store_type_annotation_node`.

Callsite compatibility:

- `_store_type_annotation_node` keeps the same signature and is still called
  from `leave_assign`, `leave_functiondef`, and `visit_arguments`.
- `_check_imports` is unchanged and consumes `_type_annotation_names` exactly as
  before.

Compatibility status: pass.
