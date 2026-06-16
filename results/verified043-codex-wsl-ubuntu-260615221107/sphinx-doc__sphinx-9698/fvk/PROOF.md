# Constructed Proof

Constructed, not machine-checked.

## Machine-check Commands

These commands were not run in this session:

```sh
kompile fvk/mini-python-domain.k --backend haskell
kast --backend haskell fvk/python-domain-index-spec.k
kprove fvk/python-domain-index-spec.k
```

Expected successful result after machine checking: `#Top`.

## Proof Shape

There are no loops or recursive calls in `PyMethod.get_index_text()`, so no
circularity claim is required. The proof is branch-by-branch symbolic execution
over the mini semantics in `mini-python-domain.k`.

## Qualified Property Case

Assume `property in self.options` and `name_cls[0]` is qualified as `CLS.METH`.
The Python code executes the `try` branch and computes `clsname, methname` with
`name.rsplit('.', 1)`. If `modname` and `add_module_names` are true, `clsname`
is rewritten to `modname + '.' + clsname`; otherwise it is unchanged.

The next branch in V1/V2 is now:

```python
if 'property' in self.options:
    return _('%s (%s property)') % (methname, clsname)
```

Therefore every qualified property-option input reaches property-shaped text
without callable parentheses. This discharges PO-1, PO-3, and PO-5.

## Unqualified Property Case

Assume `property in self.options` and `name.rsplit('.', 1)` raises
`ValueError`. The code enters the exception path. If a module is present it
returns `'%s (in module %s)'`; otherwise it returns the bare name.

Neither return path inserts `()`. This discharges PO-2.

## Property Precedence

The property branch is checked before `classmethod` and `staticmethod` in the
qualified path. In the unqualified path it is checked before the module method
fallback. Therefore adding `classmethod` or `staticmethod` cannot re-route a
property-option entry to callable method text. This discharges PO-3.

## Non-property Frame

If `property not in self.options`, the new property branches are skipped. The
remaining branches are the pre-existing callable formats:

- class method: `'%s() (%s class method)'`;
- static method: `'%s() (%s static method)'`;
- normal method: `'%s() (%s method)'`;
- module fallback: `'%s() (in module %s)'`;
- no-module fallback: `'%s()'`.

This discharges PO-4 and PO-5.

## Caller and Compatibility Frame

`PyObject.add_target_and_index()` still obtains `indextext =
self.get_index_text(modname, name_cls)` and appends it unchanged as
`('single', indextext, node_id, '', None)` when indexing is enabled. The V1
change does not touch `domain.note_object`, canonical aliases, ids, directive
signatures, or cross-reference roles. This discharges PO-6 and PO-7.

## Findings from the Proof

The stale public test expectation `meth5() (Class property)` conflicts with the
public issue and is marked SUSPECT in F-002. The proof supports keeping the V1
source change and not applying additional production edits.

## Test Guidance

No tests were run and no tests were edited. After machine checking, tests that
assert property-option index text without `()` for qualified and unqualified
names would be subsumed by PO-1 and PO-2. Integration tests covering doctree
construction and writer behavior should remain because this proof models only
`get_index_text()` and the index append protocol.
