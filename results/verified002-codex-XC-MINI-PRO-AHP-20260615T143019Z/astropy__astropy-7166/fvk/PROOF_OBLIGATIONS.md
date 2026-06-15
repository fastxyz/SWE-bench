# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-01: Data Descriptor Eligibility

Claim: `is_inheritable_member(val)` is true for Python functions and data
descriptors.

Intent evidence: E1-E3.

Code path:

```python
def is_inheritable_member(val):
    return inspect.isfunction(val) or inspect.isdatadescriptor(val)
```

Discharge: a `property` object is a data descriptor, so the property override
case reaches the doc-inheritance block.

## PO-02: Method Compatibility

Claim: public methods with `__doc__ is None` continue to inherit docs exactly as
before.

Intent evidence: E4.

Code path: functions remain eligible; non-descriptor members use the original
dynamic `getattr(base, key, None)` lookup.

## PO-03: Descriptor Lookup Does Not Invoke `__get__`

Claim: data-descriptor inheritance inspects the inherited descriptor object,
not the value returned by descriptor access.

Intent evidence: E1-E3 plus Astropy's property subclasses.

Code path:

```python
if inspect.isdatadescriptor(val):
    super_method = inspect.getattr_static(base, key, None)
```

Discharge: static lookup returns the raw inherited member for doc inspection.

## PO-04: First MRO Member Wins

Claim: the first base-class member found by `cls.__mro__[1:]` supplies the
docstring; later bases do not overwrite it.

Intent evidence: E5.

Code path: the loop breaks after the first non-`None` `super_method`.

## PO-05: Explicit Docs And Ineligible Members Are Framed

Claim: members with existing docs, private non-dunder names, or non-inheritable
kinds are unchanged.

Intent evidence: E6-E7.

Code path: the inheritance block runs only when all three guards hold:
`is_inheritable_member(val)`, `is_public_member(key)`, and `val.__doc__ is None`.

## PO-06: Public API Compatibility

Claim: the fix does not alter the metaclass signature, export, caller contract,
or public/private filtering.

Intent evidence: E7.

Discharge: only internal eligibility, lookup, and assignment handling changed.

## PO-07: Read-Only Descriptor Doc Does Not Abort Class Creation

Claim: if an eligible data descriptor cannot accept `__doc__` assignment, the
metaclass leaves it unchanged and continues.

Intent evidence: E8.

Code path:

```python
try:
    val.__doc__ = super_method.__doc__
except (AttributeError, TypeError):
    pass
```

Discharge: both expected assignment-failure exceptions are caught; no exception
escapes from this new descriptor path.

## PO-08: Superclass Initialization Still Runs

Claim: `super().__init__(name, bases, dct)` is still called after the inheritance
pass.

Intent evidence: Python metaclass compatibility convention.

Code path: unchanged final statement of `InheritDocstrings.__init__`.

## PO-09: Termination Over Finite Inputs

Claim: the metaclass pass terminates for finite `dct.items()` and finite
`cls.__mro__`.

Intent evidence: Python class namespaces and MROs are finite during class
creation.

Discharge: both loops iterate over finite collections; no loop mutates either
collection.

## PO-10: Machine-Check Honesty

Claim: proof status remains "constructed, not machine-checked" until the K
commands are run externally and return `#Top`.

Commands not run:

```sh
kompile fvk/mini-python-inherit-docstrings.k --backend haskell
kast --backend haskell fvk/inherit-docstrings-spec.k
kprove fvk/inherit-docstrings-spec.k
```
