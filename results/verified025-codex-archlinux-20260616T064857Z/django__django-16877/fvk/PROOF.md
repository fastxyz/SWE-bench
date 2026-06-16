# Proof

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were executed.

## Claims proved in the constructed model

1. `ESCAPESEQ-MAP`: for any finite modeled sequence `L`,
   `escapeseq(L)` reaches `escapeSeq(L)`.

2. `ESCAPESEQ-JOIN-OFF`: for any finite modeled sequence `L` and separator
   `SEP`, `joinOff(escapeseq(L), SEP)` reaches
   `safe(joinSafe(escapeSeq(L), SEP))`.

## Informal proof

For `ESCAPESEQ-MAP`, reason by structural induction on `L`.

Base case: if `L` is `.Items`, the semantic equation
`escapeSeq(.Items) => .Items` returns the empty sequence. This preserves length
and order.

Step case: if `L` is `I ; REST`, the semantic equation rewrites
`escapeSeq(I ; REST)` to `conditionalEscape(I) ; escapeSeq(REST)`. By the
induction hypothesis, `escapeSeq(REST)` contains exactly the escaped elements of
`REST`, in order. Prepending `conditionalEscape(I)` gives exactly one escaped
output for the head and preserves the rest, so the whole output is the
same-order, same-length per-element escape of `L`.

The two `conditionalEscape` equations discharge the `escape` versus
`force_escape` distinction: `raw(S)` becomes `safe(htmlEscape(S))`, while
`safe(S)` remains `safe(S)`.

For `ESCAPESEQ-JOIN-OFF`, symbolic execution first applies the `joinOff` rule to
the nested `escapeseq(L)`, obtaining `joinOffEscaped(escapeSeq(L), SEP)`. The
next rule returns `safe(joinSafe(escapeSeq(L), SEP))`. Since `escapeSeq(L)` has
already converted every element with `conditionalEscape`, the join receives
escaped item content before marking the aggregate safe. This is the prompt's
required ordering.

## Source-level proof correspondence

The source body:

```python
return [conditional_escape(obj) for obj in value]
```

matches `escapeSeq(I ; REST) = conditionalEscape(I) ; escapeSeq(REST)`. Python's
list comprehension preserves iteration order and emits exactly one result per
input item.

`join(..., autoescape=False)` remains:

```python
data = arg.join(value)
return mark_safe(data)
```

Therefore the escapedness obligation must be discharged before `join`, which the
new filter does.

## Residual risk and trusted base

This is a partial-correctness proof over the stated domain of finite sequences.
Termination follows from Python list-comprehension traversal over finite
iterables, but no runtime proof was executed.

Trusted dependencies:

- Django's existing `conditional_escape()` and `escape()` implement the exact
  HTML escaping table.
- The mini-K model accurately abstracts the relevant template filter behavior.
- The K reachability proof would need to be run to upgrade this from constructed
  to machine-checked.

## Reproduce the machine check later

Do not run these in this benchmark session. They are the commands to run in an
environment with K installed:

```sh
kompile fvk/mini-python-template-filters.k --backend haskell
kast --backend haskell fvk/escapeseq-spec.k
kprove fvk/escapeseq-spec.k
```

Expected result after successful machine checking: `#Top`.

## Test guidance

No tests were read, modified, or run. Because the proof is constructed but not
machine-checked, no test-removal recommendation is made. Future tests should
cover filter registration, unsafe item escaping under `autoescape off`, already
safe item preservation, sequence order preservation, and unchanged `join`
separator behavior.
