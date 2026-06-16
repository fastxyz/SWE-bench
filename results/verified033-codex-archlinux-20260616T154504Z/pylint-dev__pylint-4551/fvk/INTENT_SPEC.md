# Intent Spec

Status: constructed for audit; no commands were executed.

## Public Intent

1. Pyreverse must use Python type hints when generating UML class diagrams.
   Evidence: the issue title says "Use Python type hints for UML generation."

2. A constructor parameter annotation must survive the common `None` default
   pattern when that parameter is assigned directly to an instance attribute.
   Evidence: the issue example is:

   ```python
   class C(object):
       def __init__(self, a: str = None):
           self.a = a
   ```

   The expected UML output is "something like: `a : String`".

3. The existing value-inference behavior must be preserved for unannotated
   assignments. Evidence: pyreverse already displays inferred value types such
   as `attr : str` and associations from assignments such as
   `self.relation = DoNothing()`.

4. Public pyreverse rendering rules should remain in charge of output shape:
   if a collected type is not already a diagram node, `ClassDiagram.class_names`
   may display it as an attribute type; if it is already a diagram node, the
   existing association path handles it.

## Domain

The proven domain is the observable path needed for the reported issue:

- assignment target is an astroid `AssignName` or `AssignAttr`;
- value inference returns zero or more astroid nodes;
- annotations are directly inferable to astroid nodes;
- an instance attribute assignment may directly assign an annotated parameter
  name, as in `self.a = a`;
- diagram rendering consumes `locals_type` and `instance_attrs_type` exactly as
  before V1.

Richer PEP 484 formatting, such as preserving the text of `Optional[str]`,
`list[str]`, string-literal forward references, or type comments, is not proven
by this FVK run. The public issue gives a simple directly inferable annotation
as the concrete expected behavior.

## Frame Conditions

- Do not change public method signatures.
- Do not modify test files.
- Do not replace existing value inference; only add annotation-derived evidence.
- If annotation inference fails, continue best-effort behavior rather than
  raising from pyreverse.
