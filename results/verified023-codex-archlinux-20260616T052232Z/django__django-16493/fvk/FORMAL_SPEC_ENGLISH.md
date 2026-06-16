# Formal Spec in English

Status: constructed for audit; not machine-checked.

The formal model abstracts `FileField` storage deconstruction into four
observable storage cases. The observable is whether the deconstructed kwargs
omit `storage` or include it, and if included, whether the value is the direct
storage object or the original callable.

## Claim DEFAULT-IMPLICIT

For a field initialized without an explicit storage argument, deconstruction
omits the `storage` kwarg.

## Claim DIRECT-DEFAULT

For a field initialized with the direct storage object `default_storage`,
deconstruction omits the `storage` kwarg because the value is the default.

## Claim DIRECT-OTHER

For a field initialized with a direct non-default storage object,
deconstruction includes `storage` with that storage object.

## Claim CALLABLE-DEFAULT

For a field initialized with a callable storage provider whose evaluated result
is `default_storage`, deconstruction includes `storage` with the original
callable provider.

## Claim CALLABLE-OTHER

For a field initialized with a callable storage provider whose evaluated result
is a non-default storage object, deconstruction includes `storage` with the
original callable provider.

## Frame conditions

The formal claims do not change the public signatures of `FileField.__init__()`
or `FileField.deconstruct()`. They preserve the default-omission behavior for
implicit/default storage and preserve existing callable-non-default
deconstruction.
