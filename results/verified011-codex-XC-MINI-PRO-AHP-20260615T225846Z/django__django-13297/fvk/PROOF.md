# FVK Proof

Status: constructed, not machine-checked. This proof was written from static
source reasoning only. No tests, Python, `kompile`, or `kprove` were run.

## Model Summary

The mini semantics abstracts the relevant `TemplateView.get()` sequence:

1. Receive URL kwargs `KW`.
2. Call `get_context_data(**KW)` and record that the virtual method observed
   exactly `KW`.
3. Let `C` be the context returned from that method.
4. Mutate `C` by wrapping only entries that are still the same object as the
   URL kwarg value.
5. Render with the mutated context.

This abstraction keeps the proof-relevant axes visible: argument identity, final
context shape, lazy-warning wrapper placement, and frame preservation for
removed or replaced entries.

## PO1 Proof: Raw Kwargs Reach `get_context_data()`

The V1 control flow in `TemplateView.get()` is:

```python
context = self.get_context_data(**kwargs)
_wrap_url_kwargs_with_deprecation_warning(context, kwargs)
return self.render_to_response(context)
```

By direct sequencing, no wrapper-producing operation occurs before the virtual
call. Therefore the kwargs observed by the override are the same URL resolver
values received by `TemplateView.get()`. This discharges PO1 and resolves F1.

## PO2 and PO4 Proof: Deprecated Context Access Still Warns Lazily

After `get_context_data()` returns, V1 invokes the helper over `(context,
kwargs)`. For each URL kwarg `(key, value)`, the helper creates a
`SimpleLazyObject` whose setup function warns with the existing
`RemovedInDjango40Warning` message and returns `value`.

Because this wrapper is created after `get_context_data()` returns, the warning
cannot fire during the user override's access to `kwargs`. Because the wrapper
is stored into the final context before `render_to_response()`, direct template
context access to unchanged URL kwargs retains the deprecation-warning behavior.
This discharges PO2 and PO4 and confirms F2.

## PO3 Proof: Removed or Replaced Entries Are Framed

The helper starts each iteration with:

```python
if key not in context or context[key] is not value:
    continue
```

Case 1: `key not in context`. The helper continues without assignment, so the
missing key remains missing.

Case 2: `key in context` but `context[key] is not value`. The helper continues
without assignment, so the replacement value remains unchanged.

Case 3: `key in context` and `context[key] is value`. The helper assigns the
lazy warning wrapper for exactly that unchanged URL kwarg.

These cases cover the finite URL kwargs map and discharge PO3. The explicit
membership check also handles the boundary case where `value is None`; a missing
key is not mistaken for a present key with value `None`. This confirms F3.

## PO5 Proof: Compatibility

The public virtual method call remains `self.get_context_data(**kwargs)`.
`TemplateView.get()` still accepts `(request, *args, **kwargs)` and still returns
`self.render_to_response(context)`. No public override is called with new
parameters. Static source search found the changed helper only in
`repo/django/views/generic/base.py`; it is private. This discharges PO5 and
confirms F4.

## PO6 Proof: ORM Scope

No ORM source files were changed. The code no longer manufactures
`SimpleLazyObject` values before user `get_context_data()` code runs, so the
reported `TemplateView` regression is removed without changing standalone ORM
behavior for explicitly supplied lazy objects. This discharges PO6 and confirms
F5.

## Residual Risk

This is a partial-correctness proof over an abstract mini semantics, not a
machine-checked proof over full Python and Django. It assumes the documented
context contract: `get_context_data()` returns a mutable mapping. The proof does
not cover arbitrary non-mapping custom returns and does not prove termination,
though the audited helper iterates over a finite kwargs mapping in normal Django
use.

## Test Recommendation

No tests were removed or modified. Existing deprecation tests should be kept
unless the constructed K claims are later machine-checked and the project
decides to treat equivalent in-domain unit tests as redundant. A useful
regression test, if tests could be edited, would assert that an override of
`get_context_data()` receives a plain slug value while final context access to
an unchanged URL kwarg still warns.

## Reproduce Later

These commands are for a later environment with K installed:

```sh
kompile fvk/mini-templateview.k --backend haskell
kast --backend haskell fvk/templateview-spec.k
kprove fvk/templateview-spec.k
```
