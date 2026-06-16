# FVK Proof Obligations

Status: constructed, not machine-checked. These obligations are written in an
abstract K style over the mini metadata-flow semantics described in
`fvk/SPEC.md`.

## PO-001: Decorator-Facing Partial Preserves Wrapper Assignments

Provenance: E-001, E-002, E-006.

Claim:

```k
// SPEC-PROVENANCE:
// - prompt: "method_decorator() should preserve wrapper assignments"
// - prompt: "partial object ... does not have ... __name__, __module__ etc"
// - code: V1 applies wraps(method) to the partial before decorators run.
claim
  <k> makeBoundCallable(METHOD, SELF)
      => copyAssigned(partial(bound(METHOD, SELF)), METHOD) ... </k>
  requires callableDescriptor(METHOD)
  ensures assignedEqual(result, METHOD, WRAPPER_ASSIGNMENTS)
  [all-path]
```

Required side condition: `METHOD` may be missing some assigned attributes; the
claim only requires equality for assigned attributes present on `METHOD`.

Discharge argument: `functools.wraps(method)` is equivalent to
`functools.update_wrapper(wrapper, method)` with default assignments and updates.
The wrapper is the partial. Therefore each present assigned attribute is set on
the partial before the first decorator call.

Status: discharged by V1.

## PO-002: Issue Logger Cannot Fail on `func.__name__`

Provenance: E-003, F-001.

Claim:

```k
// SPEC-PROVENANCE:
// - prompt example: logger reads func.__name__.
// - finding F-001: pre-fix plain partial made the lookup undefined.
claim
  <k> applyDecorator(loggerReadsName, makeBoundCallable(METHOD, SELF))
      => decoratedCallable(loggerReadsName, makeBoundCallable(METHOD, SELF))
      ... </k>
  requires callableDescriptor(METHOD)
   andBool hasAttr(METHOD, "__name__")
  ensures readAttr(decoratorInput, "__name__") ==K readAttr(METHOD, "__name__")
  [all-path]
```

Discharge argument: PO-001 gives the decorator input a defined `__name__` equal
to `METHOD.__name__`. The lookup that failed before V1 is therefore defined.

Status: discharged by V1.

## PO-003: Call Target and Argument Binding Are Preserved

Provenance: E-004, E-005.

Claim:

```k
// SPEC-PROVENANCE:
// - source comment: bound_method has no self argument but closes over self.
// - public tests: signature-preservation and descriptor behavior.
claim
  <k> call(copyAssigned(partial(bound(METHOD, SELF)), METHOD), ARGS, KWARGS)
      => call(bound(METHOD, SELF), ARGS, KWARGS) ... </k>
  requires callableDescriptor(METHOD)
  ensures sameReturnValue(result, call(METHOD, SELF, ARGS, KWARGS))
  [all-path]
```

Discharge argument: `wraps(method)` mutates metadata on the partial; it does not
alter the partial's underlying callable, positional arguments, keyword
arguments, or descriptor binding.

Status: discharged by V1.

## PO-004: Decorator Order Is Preserved

Provenance: E-005.

Claim:

```k
// SPEC-PROVENANCE:
// - public tests: tuple decorators produce normal decorator order.
claim
  <k> applyDecorators(DECS, BASE) => normalDecoratorStack(DECS, BASE) ... </k>
  requires finiteDecoratorSequence(DECS)
  ensures sameDecoratorOrder(result, normalDecoratorStack(DECS, BASE))
  [all-path]
```

Discharge argument: V1 changes only construction of `BASE`; it does not modify
the existing `decorators[::-1]` normalization or the `for dec in decorators`
loop.

Status: discharged by V1.

## PO-005: Outer Wrapper Attribute Propagation Is Preserved

Provenance: E-005.

Claim:

```k
// SPEC-PROVENANCE:
// - public tests: decorator-added attrs and method __doc__/__name__ are
//   visible on Test.method and Test().method.
claim
  <k> finalizeMethodWrapper(WRAPPER, METHOD, DECS)
      => updateWrapper(copyDecoratorAttrs(WRAPPER, DECS), METHOD) ... </k>
  requires finiteDecoratorSequence(DECS)
  ensures outerWrapperAttrsPreserved(result, METHOD, DECS)
  [all-path]
```

Discharge argument: V1 does not edit `_update_method_wrapper()` or the final
`update_wrapper(_wrapper, method)`. The existing attribute-copying behavior is
framed unchanged.

Status: discharged by framing.

## PO-006: Public Compatibility Is Preserved

Provenance: E-004, E-005, public compatibility audit in `fvk/SPEC.md`.

Claim:

```k
// SPEC-PROVENANCE:
// - public API: method_decorator(decorator, name='') remains unchanged.
// - public tests/callsites: existing call behavior and error behavior remain.
claim
  <k> publicMethodDecoratorAPI(V1) => publicMethodDecoratorAPI(V0) ... </k>
  ensures sameSignature(method_decorator)
   andBool sameInvalidNameErrors
   andBool sameNonCallableAttributeErrors
   andBool strongerDecoratorInputMetadata
  [all-path]
```

Discharge argument: the source diff is limited to the local `bound_method`
assignment inside `_wrapper`. No public signature, exception branch, class
decoration branch, or iterable normalization branch changed.

Status: discharged by source-diff framing.

## PO-007: Proof Honesty Gate

Provenance: F-005 and FVK `verify.md`.

Claim:

```k
// SPEC-PROVENANCE:
// - FVK honesty gate: constructed proof is not machine-checked.
claim
  <k> proofStatus => constructedNotMachineChecked ... </k>
  ensures doNotDeleteTests andBool requireKproveForMachineCheckedStatus
  [all-path]
```

Discharge argument: this session did not run tests, Python, `kompile`,
`kast`, or `kprove`. The only valid conclusion is a constructed proof and a
code decision justified by the obligations above.

Status: discharged as process obligation.

## Commands to Machine Check Later

Do not run these in this benchmark environment. They are recorded for a future
environment with K installed:

```sh
kompile fvk/mini-method-decorator.k --backend haskell
kast --backend haskell fvk/method-decorator-spec.k
kprove fvk/method-decorator-spec.k
```

Expected result if the abstract semantics is accepted and the obligations close:
`#Top`.
