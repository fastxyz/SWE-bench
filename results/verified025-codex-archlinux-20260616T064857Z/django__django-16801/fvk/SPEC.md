# SPEC: ImageField post_init registration

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

This FVK pass audits the V1 change in
`repo/django/db/models/fields/files.py`, specifically
`ImageField.contribute_to_class()` and its interaction with
`ImageField.update_dimension_fields()`, `ImageFileDescriptor.__set__()`, and
`Model.__init__()` sending `post_init`.

## Intent Spec

I1. A concrete model with an `ImageField` that has no `width_field` and no
`height_field` must not register that field's `update_dimension_fields()` as a
`post_init` receiver.

I2. A concrete model with an `ImageField` that has at least one of
`width_field` or `height_field` must continue to register
`update_dimension_fields()` as a `post_init` receiver.

I3. Abstract models must not directly register the receiver; concrete subclasses
that receive a dimension-bearing field must still be eligible for registration.

I4. Assignment after model initialization must continue to force dimension
updates through `ImageFileDescriptor.__set__()` when a previous file value is
present.

I5. No public API, field constructor argument, descriptor protocol, or signal API
shape should change.

## Public Evidence Ledger

E1. Source: prompt. Quote: "ImageField unnecessarily adds a post_init signal
handler to the model." Obligation: remove unnecessary receiver registration.
Status: encoded by claim C-NO-DIMENSIONS.

E2. Source: prompt. Quote: "the post_init signal handler is a noop because we
don't use the width_field / height_field." Obligation: no-dimension fields do
not need post-init work. Status: encoded by claims C-NO-DIMENSIONS and
U-NO-DIMENSIONS.

E3. Source: prompt. Quote: "If width_field and height_field are not set,
removing the post_init signal should have no effect." Obligation: behavioral
frame condition for no-dimension fields. Status: encoded by claim
C-NO-DIMENSIONS plus the update no-op claim U-NO-DIMENSIONS.

E4. Source: implementation comment in `files.py`. Quote:
"dimension fields declared after their corresponding image field don't stay
cleared by Model.__init__". Obligation: keep post-init receiver for fields with
dimension metadata. Status: encoded by claims C-WIDTH, C-HEIGHT, and C-BOTH.

E5. Source: implementation comment in `files.py`. Quote: "Only run
post-initialization dimension update on non-abstract models". Obligation:
abstract models do not directly register the receiver. Status: encoded by claim
C-ABSTRACT.

E6. Source: implementation comment in `ImageFileDescriptor.__set__()`. Quote:
"Assignment happening outside of Model.__init__() will trigger the update right
here." Obligation: assignment-time forced updates remain independent of receiver
registration. Status: encoded by claim A-PREVIOUS-FILE.

E7. Source: public tests in `tests/model_fields/models.py`. Quote:
"Model that defines an ImageField with no dimension fields." Obligation:
no-dimension `ImageField` is a supported public model shape. Status: encoded by
C-NO-DIMENSIONS, not treated as a legacy bug.

E8. Source: public tests in `tests/model_fields/models.py`. Quote:
"Abstract model that defines an ImageField with only one dimension field to make
sure the dimension update is correctly run on concrete subclass instance
post-initialization." Obligation: concrete inherited dimension-bearing fields
must still register. Status: encoded by C-HEIGHT and C-ABSTRACT together.

## Formal Model

The model intentionally represents only the property under audit: whether the
receiver is registered and whether dimension updates can occur on the remaining
paths.

Definitions:

- `Abs`: `true` when `cls._meta.abstract` is true.
- `W`: `true` when `self.width_field` is configured.
- `H`: `true` when `self.height_field` is configured.
- `D = W or H`: at least one dimension field exists.
- `Connected`: whether `signals.post_init.connect(...)` is called.
- `Prev`: whether `ImageFileDescriptor.__set__()` saw a prior field value.

Candidate rule from V1:

```text
Connected = (not Abs) and (W or H)
```

Post-init update rule already present before V1:

```text
update_dimension_fields returns without state changes when not (W or H).
```

Assignment rule unchanged by V1:

```text
ImageFileDescriptor.__set__ calls update_dimension_fields(force=True)
iff Prev is true.
```

## K Claims

The formal core is materialized in `fvk/mini-django-imagefield.k` and
`fvk/imagefield-post-init-spec.k`. The claims are also shown here for review.
They are written as a minimal mini-Django fragment rather than a full
Python/Django semantics.

```k
module MINI-DJANGO-IMAGEFIELD
  imports BOOL

  syntax Action ::= contribute(Bool, Bool, Bool)
                  | updateDims(Bool, Bool, Bool)
                  | assignImage(Bool)
  syntax Result ::= connected(Bool)
                  | dimensionsChanged(Bool)
                  | forceUpdateCalled(Bool)
  syntax KResult ::= Result

  configuration <k> $PGM:Action </k>

  // contribute(Abs, W, H)
  rule <k> contribute(Abs:Bool, W:Bool, H:Bool)
        => connected(notBool Abs andBool (W orBool H)) </k>

  // updateDims(W, H, Deferred) abstracts the early return:
  // no dimension fields or deferred image field means no dimension change.
  rule <k> updateDims(false, false, Deferred:Bool)
        => dimensionsChanged(false) </k>
  rule <k> updateDims(W:Bool, H:Bool, true)
        => dimensionsChanged(false) </k>
    requires W orBool H
  rule <k> updateDims(W:Bool, H:Bool, false)
        => dimensionsChanged(true) </k>
    requires W orBool H

  // assignImage(Prev) abstracts ImageFileDescriptor.__set__().
  rule <k> assignImage(Prev:Bool) => forceUpdateCalled(Prev) </k>
endmodule

module IMAGEFIELD-POST-INIT-SPEC
  imports MINI-DJANGO-IMAGEFIELD

  // SPEC-PROVENANCE: E1, E2, E3.
  claim <k> contribute(false, false, false)
        => connected(false) </k> [all-path]

  // SPEC-PROVENANCE: E4, E8.
  claim <k> contribute(false, true, false)
        => connected(true) </k> [all-path]

  // SPEC-PROVENANCE: E4, E8.
  claim <k> contribute(false, false, true)
        => connected(true) </k> [all-path]

  // SPEC-PROVENANCE: E4.
  claim <k> contribute(false, true, true)
        => connected(true) </k> [all-path]

  // SPEC-PROVENANCE: E5.
  claim <k> contribute(true, W:Bool, H:Bool)
        => connected(false) </k> [all-path]

  // SPEC-PROVENANCE: E2, E3.
  claim <k> updateDims(false, false, Deferred:Bool)
        => dimensionsChanged(false) </k> [all-path]

  // SPEC-PROVENANCE: E6.
  claim <k> assignImage(true)
        => forceUpdateCalled(true) </k> [all-path]
endmodule
```

The non-executed commands are:

```sh
cd fvk
kompile mini-django-imagefield.k --backend haskell
kast --backend haskell imagefield-post-init-spec.k
kprove imagefield-post-init-spec.k
```

## Formal Spec English

FSE1. On a concrete class with `width_field is None` and `height_field is
None`, `contribute_to_class()` must not connect the `post_init` receiver.
Adequacy: pass for I1 and E1-E3.

FSE2. On a concrete class with width only, height only, or both dimensions
configured, `contribute_to_class()` must connect the receiver. Adequacy: pass
for I2 and E4/E8.

FSE3. On an abstract class, `contribute_to_class()` must not connect the
receiver regardless of dimension configuration. Adequacy: pass for I3 and E5.

FSE4. Calling `update_dimension_fields()` with no configured dimension fields
has no dimension-state effect. Adequacy: pass for I1 and E2/E3.

FSE5. Assignment after initialization with a previous file value still calls the
forced dimension update path. Adequacy: pass for I4 and E6.

FSE6. The candidate changes only the guard around receiver registration and does
not alter public signatures or descriptor APIs. Adequacy: pass for I5.

## Compatibility Audit

Changed public symbol: `ImageField.contribute_to_class()`.

Compatibility result: pass. The method signature is unchanged, the constructor
arguments `width_field` and `height_field` are unchanged, the descriptor class is
unchanged, `update_dimension_fields()` remains callable with the same signature,
and the signal API invocation is unchanged when it still occurs.
