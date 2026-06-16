# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and the formal proof obligations. No tests or tools
were run.

## F1: V1 fixed the direct `abc.ABC` symptom

Input:

```python
import abc
X = ...  # type: abc.ABC
```

V0 observed behavior from the issue: `W0611: Unused import abc`.

Expected behavior from the issue: no `unused-import`.

V1 result by source inspection: `_store_type_annotation_node` gained an
`astroid.Attribute` branch, so `abc` is recorded from `abc.ABC` and
`_check_imports` sees `imported_name == "abc"` in `_type_annotation_names`.

Classification: fixed direct bug.

Proof obligations: PO1 and PO3.

## F2: V1 still stopped too early for `typing.*[...]` annotations

Input:

```python
import abc
import typing
X = ...  # type: typing.Optional[abc.ABC]
```

V1 observed by source inspection: `_store_type_annotation_node` appended
`typing` when the subscript value was `typing.Optional`, then returned before
collecting names from the subscript arguments. That leaves `abc` unrecorded.

Expected from public intent: `abc` is still a module used in a type comment, so
`unused-import` should not be emitted for `abc`.

V2 change: the `typing` special case no longer returns early. The helper
records `typing` and continues collecting nested `Name` and `Attribute` nodes.

Classification: code bug in V1, repaired.

Proof obligations: PO2, PO4.

## F3: V1 did not align qualified annotation names with dotted import keys

Input:

```python
import xml.etree
X = ...  # type: xml.etree.ElementTree
```

V1 observed by source inspection: collecting only bare `Name` nodes can record
`xml`, but `_fix_dot_imports` may pass `xml.etree` as the import key checked by
`_check_imports`. If only `xml` is recorded, the predicate
`imported_name in _type_annotation_names` can fail for `imported_name ==
"xml.etree"`.

Expected from the checker's own import-key flow: a qualified type comment should
record dotted prefixes that match possible imported names.

V2 change: `_qualified_names_from_attribute` records dotted prefixes such as
`xml` and `xml.etree`, and `_store_type_annotation_node` stores those prefixes
for attribute annotations.

Classification: code bug in V1, repaired.

Proof obligations: PO2, PO4.

## F4: Existing simple-name behavior must be preserved

Input:

```python
from abc import ABC
Y = ...  # type: ABC
```

Expected from the issue: no `unused-import`.

V2 reasoning: the `astroid.Name` branch is unchanged and still appends `ABC`.

Classification: frame condition, confirmed.

Proof obligations: PO2, PO3.

## F5: Tool execution is intentionally absent

The FVK proof is constructed only. The exact `kompile`, `kast`, and `kprove`
commands are recorded in `fvk/PROOF_OBLIGATIONS.md` and `fvk/PROOF.md`, but were
not executed because this task forbids running K tooling, tests, Python, or
project code.

Classification: proof honesty boundary, not a code bug.

Proof obligations: all obligations remain "constructed, not machine-checked."
