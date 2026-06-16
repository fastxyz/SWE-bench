# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbol

`sphinx.domains.python._parse_annotation(annotation: str) -> List[Node]`

## Signature Compatibility

No signature change. The function still accepts a string annotation and returns
a list of docutils nodes.

## Caller Compatibility

Known source callers from `repo/sphinx/domains/python.py`:

- argument annotation rendering in `_parse_arglist()`
- return annotation rendering in Python object signature handling

Both consume a list of nodes and do not depend on the internal separator-removal
implementation. The V2 change preserves the return shape.

## Override And Virtual Dispatch Compatibility

No class method, virtual dispatch call, subclass override, or public protocol was
changed.

## Producer/Consumer Shape

The changed branches still produce `addnodes.desc_sig_punctuation` for
punctuation and leave text/name handling to the existing post-processing step.
No consumer needs to change.

## Compatibility Conclusion

No public compatibility risk was found. The change is behaviorally additive for
previously broken or malformed empty delimiter cases and preserves existing
non-empty outputs.
