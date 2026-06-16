# Formal Spec English

The constructed K claims in `autodoc-mock-spec.k` mean:

1. For any `TypeVar`-like generic parameter with string name `T`, calling
   `_make_subclass(TypeVarName(T), module, superclass)` reaches a state where
   the created type's Python class-name argument is `T` and the display name is
   `module + "." + T`.
2. For any existing string name `NAME`, calling `_make_subclass(NAME, module,
   superclass)` preserves the prior dotted display result
   `module + "." + NAME`.
3. For any modeled in-domain name value, `_make_subclass()` first maps it to a
   string `normalizedName(name)`, then uses only that string for display-name
   concatenation and type construction.
4. For `_MockObject.__getitem__`, generic subscription with a `TypeVar`-like key
   reaches a mock instance whose underlying generated type was constructed with
   a string name and dotted display name. The subscription path therefore does
   not perform `str + TypeVar`.

All proof results are partial correctness only and are constructed, not
machine-checked.
