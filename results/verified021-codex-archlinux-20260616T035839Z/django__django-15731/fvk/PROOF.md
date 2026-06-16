# FVK Proof

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were executed.

## Claim

For every eligible queryset method copied onto a generated manager by
`BaseManager._get_queryset_methods()`, the V1 implementation exposes the
queryset method's bound signature through `inspect.signature()` while preserving
the original method-selection and call-forwarding behavior.

## Constructed Proof Sketch

1. `_get_queryset_methods()` iterates over functions on the queryset class and
   applies the same eligibility checks before and after V1. This discharges
   PO-005.

2. For each eligible `(name, method)` pair, `create_method()` constructs
   `manager_method(self, *args, **kwargs)`. V1 decorates that function with
   `@wraps(method)`. By the standard effect of `functools.wraps()`, the returned
   proxy has `__wrapped__` pointing to `method` and receives the default copied
   metadata. This discharges PO-002.

3. Python's `inspect.signature()` follows `__wrapped__` when computing a
   callable's signature. When the copied manager method is accessed through a
   manager instance, it is a bound method, so the receiver parameter corresponding
   to `self` is omitted from the displayed signature. Therefore, for original
   queryset method parameters `(self, p1, ..., pn)`, the bound manager method
   displays `(p1, ..., pn)`. This discharges PO-001 and PO-004.

4. In the pre-fix implementation, the proxy had the runtime shape
   `(self, *args, **kwargs)` and no `__wrapped__` link to `method`; manual
   assignment of `__name__` and `__doc__` is insufficient for
   `inspect.signature()` to recover the original callable's parameters. This
   localizes the reported failure and discharges PO-003.

5. The body of `manager_method()` remains
   `return getattr(self.get_queryset(), name)(*args, **kwargs)`. The source edit
   does not change argument passing, queryset lookup, method lookup, return
   value, or exception behavior for actual calls. This discharges PO-006.

6. Because no K or Python tooling was executed, the proof remains constructed
   only. This satisfies the honesty gate PO-007 and leaves F-005 as residual
   process risk rather than a source-code defect.

## Abstract Symbolic Derivation

Let:

- `M = method`, a queryset function with parameters `[self] + P`.
- `G = manager_method`, the generated forwarding function with concrete runtime
  parameters `[self, *args, **kwargs]`.
- `W = wraps(M)(G)`.
- `B = bound(manager_instance, W)`.

Rules:

- `wraps(M)(G)` gives `W.__wrapped__ = M`.
- `signature(bound(receiver, F)) = drop_receiver(signature(F))`.
- `signature(F)` follows `F.__wrapped__` when present.

Derivation:

```text
signature(B)
= signature(bound(manager_instance, W))
= drop_receiver(signature(W))
= drop_receiver(signature(W.__wrapped__))
= drop_receiver(signature(M))
= drop_receiver([self] + P)
= P
```

This is exactly the intended observable: the copied manager method displays the
same public parameters as the original queryset method after normal binding.

## Adequacy and Compatibility

- The proof target matches the issue: it verifies introspection-visible
  signatures, not database side effects.
- The proof is generic over parameter lists, so it covers both the issue's
  displayed `bulk_create()` example and the longer `bulk_create()` signature in
  this checkout.
- Public compatibility is preserved because the runtime callable still accepts
  `*args` and `**kwargs`; V1 changes introspection metadata, which is the
  behavior the issue requires changing.
- No public callsite or override shape is changed. The generated method remains
  a manager method with the same forwarding implementation.

## Commands for Later Machine Checking

These commands are recorded for a future environment with K tooling. They were
not executed in this session.

```sh
kompile fvk/mini-python-signature.k --backend haskell
kast --backend haskell fvk/manager-signature-spec.k
kprove fvk/manager-signature-spec.k
```

Expected result after a complete executable K encoding: `#Top`.

## Test Recommendation

No tests were read, run, modified, or recommended for deletion. If future public
tests assert concrete manager signatures such as `bulk_create`, they are
candidate redundancy only after the formal claims are machine-checked. Keep all
tests until then.
