# Baseline notes — pylint-dev/pylint #4551

## Issue

`pyreverse` ignores PEP 484 type hints when generating UML class diagrams.
For code such as:

```python
class C:
    def __init__(self, a: str = None):
        self.a = a
```

the diagram showed `a` with no type, because the only information pyreverse used
for attributes was *inference* of the assigned value. Here `self.a = a` infers to
`None` (the parameter's default), so no useful type is shown. The reporter wanted
to see `a : str` (the declared annotation). The same gap applied to method
signatures, which were rendered with bare parameter names and no return type.

## Root cause

pyreverse built its attribute/local type maps purely from `astroid`'s value
inference:

* `inspector.Linker.visit_assignname` did `values = set(node.infer())`.
* `inspector.Linker.handle_assignattr_type` did `values = set(node.infer())`.

Inference never consulted the explicit annotations attached to:

* annotated assignments (`x: int = ...`, i.e. `astroid.AnnAssign`), or
* the constructor/method parameter whose value is stored on the instance
  (`self.a = a`, where `a` is annotated in the signature).

The writer (`writer.DotWriter.get_values`) likewise emitted only `name` for each
parameter and nothing for return types.

## Fix

The fix makes pyreverse *prefer the declared annotation* over inference, and adds
annotations to the rendered method signatures.

### `pylint/pyreverse/utils.py`
Added three helpers (and the `astroid` / `typing` imports they need):

* `get_annotation_label(ann)` — turns an annotation node into a string
  (`Name.name`, or `Subscript.as_string()` for things like `List[int]`).
* `get_annotation(node)` — returns the annotation node for an `AssignName` /
  `AssignAttr`:
  * if the parent is an `AnnAssign`, use its `.annotation`;
  * if the node is an `AssignAttr` (e.g. `self.a = a`), resolve the right-hand
    name back to the enclosing method's parameter annotations
    (`dict(zip(scope.locals, scope.args.annotations))`).
  When the assigned/inferred default is `None`, the label is wrapped as
  `Optional[...]` (so `a: str = None` is shown as `Optional[str]`). The computed
  label is written onto the annotation node's `.name` so downstream code that
  reads `.name` (e.g. `class_names`) can use it. The `not label.startswith("Optional")`
  guard keeps this idempotent if a node is processed more than once.
* `infer_node(node)` — returns `{annotation}` when an annotation exists, otherwise
  falls back to `set(node.infer())` (empty set on `InferenceError`). This is the
  single entry point the inspector now uses.

### `pylint/pyreverse/inspector.py`
Replaced the two raw `set(node.infer())` calls (in `visit_assignname` and
`handle_assignattr_type`) with `utils.infer_node(node)`, so annotations win over
inference while the inference fallback is preserved unchanged.

### `pylint/pyreverse/diagrams.py`
`ClassDiagram.class_names` only accepted `astroid.ClassDef` nodes. Since
`instance_attrs_type` / `locals_type` can now contain annotation nodes, the
`isinstance` check was widened to `(astroid.ClassDef, astroid.Name, astroid.Subscript)`.
The existing `hasattr(node, "name")` / `not self.has_node(node)` guards still apply.

### `pylint/pyreverse/writer.py`
`DotWriter.get_values` now renders parameter annotations (`name: type`) and a
return-type suffix (`(...): type`) for each method, using `get_annotation_label`.
When no annotations are present the output is byte-for-byte identical to before
(e.g. `set_value(value)`), so existing diagrams are unaffected.

### `ChangeLog`
Added a feature entry.

## Why other consumers stay correct

`diadefslib.DiaDefGenerator.get_associated` and
`diagrams.ClassDiagram.extract_relationships` also iterate over the type maps, but
both only act on `astroid.Instance` / `astroid.ClassDef` nodes and silently skip
anything else, so the newly-added annotation nodes never create spurious
association edges and never raise.

## Assumptions / alternatives considered

* **`Optional[...]` for `= None` defaults.** The issue literally asked for
  `a : str`, but a parameter typed `str` that defaults to `None` is effectively
  optional, so `Optional[str]` is the more accurate label. This matches the
  intent ("`None` as a default for mutable data") and is what the implementation
  encodes.
* **Annotation preferred over inference (not merged with it).** `infer_node`
  returns the annotation *instead of* the inferred value when an annotation is
  present, avoiding noisy combinations like `Optional[str], NoneType`.
* **Parameter-annotation lookup keyed on the RHS name.** `self.a = a` is resolved
  by matching the assigned name (`a`) against the method's parameter annotations.
  Non-name right-hand sides (constants, calls, tuples) raise `AttributeError`,
  which is caught and falls back to inference — preserving prior behaviour for
  `self.attr = 'literal'` (still inferred as `str`).
* **VCG output left unchanged.** Only the Dot writer renders method signatures in
  the tested output; the legacy VCG writer was left as-is to keep the change
  minimal and avoid untested format churn.
* **Backward compatibility.** For annotation-free code (including the existing
  `tests/data` fixtures) every code path falls back to the original inference and
  signature formatting, so previously generated diagrams remain identical.
