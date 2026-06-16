# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Single non-conditional lookup child uses kwargs

Precondition:

- `children == [child]`
- `conditional(child) is False`
- `lookup_key(child)` and `lookup_value(child)` are defined
- `connector == "AND"`
- `negated is False`

Claim:

`deconstruct(Q([child], "AND", False))` returns:

```text
("django.db.models.Q", (), {lookup_key(child): lookup_value(child)})
```

Purpose: preserves `Q(x=1).deconstruct()` and the public single-lookup test.

## PO-2: Single conditional child uses args and does not index the child

Precondition:

- `children == [child]`
- `conditional(child) is True`
- `connector == "AND"`
- `negated is False`

Claim:

`deconstruct(Q([child], "AND", False))` returns:

```text
("django.db.models.Q", (child,), {})
```

The proof must not require `lookup_key(child)` or `lookup_value(child)`.

Purpose: fixes `Q(Exists(...)).deconstruct()` and other supported conditional
expression children.

## PO-3: Single nested `Q` child remains positional

Precondition:

- `children == [child_q]`
- `child_q` is a `Q`
- `conditional(child_q) is True`
- `connector == "AND"`
- `negated is False`

Claim:

`deconstruct(Q([child_q], "AND", False))` returns:

```text
("django.db.models.Q", (child_q,), {})
```

Purpose: preserves the public nested-`Q` behavior.

## PO-4: Multiple children use args

Precondition:

- `len(children) != 1`
- `connector == "AND"`
- `negated is False`

Claim:

`deconstruct(Q(children, "AND", False))` returns:

```text
("django.db.models.Q", tuple(children), {})
```

Purpose: preserves multi-condition deconstruction.

## PO-5: Positional branch preserves connector and negation metadata

Precondition:

- execution reaches the positional branch
- `connector` may differ from `"AND"`
- `negated` may be `True`

Claim:

- if `connector != "AND"`, returned `kwargs` contains
  `{"_connector": connector}`
- if `negated is True`, returned `kwargs` contains `{"_negated": True}`
- both metadata entries are present when both conditions hold

Purpose: ensures the V1 conditional-child fix does not lose metadata on the
path now used by `Q(Exists(...))`.

## PO-6: Unsupported arbitrary children are not in the proven domain

Precondition:

- `children == [child]`
- `conditional(child) is False`
- lookup-pair indexing is not defined for `child`

Claim:

No correctness claim is made for this input class.

Purpose: records the explicit scope boundary for inputs such as `Q(False)`.
This is not a hidden assumption; it is derived from the public hint that says
conditional-expression handling is sufficient while preserving the current
format.

## Proof Commands Not Executed

If these obligations were translated into a full K fragment, the commands would
be recorded and run outside this benchmark as:

```sh
kompile fvk/mini-q-deconstruct.k --backend haskell
kast --backend haskell fvk/q-deconstruct-spec.k
kprove fvk/q-deconstruct-spec.k
```

Expected result after a real machine check: `#Top` for PO-1 through PO-5. PO-6
is a stated non-domain boundary rather than a proof claim.

