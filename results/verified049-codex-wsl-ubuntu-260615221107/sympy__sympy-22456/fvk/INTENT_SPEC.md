# Intent Spec

Status: constructed from public intent and local source evidence; no tests or
tooling were run.

## Required behavior

I1. For every `sympy.codegen.ast.String` instance, including subclasses such as
`QuotedString`, `Comment`, and ordinary user subclasses, the standard `Basic`
reconstruction invariant must hold:

```python
expr.func(*expr.args) == expr
```

I2. Since the issue states that `String` is a `Basic` subclass, the arguments
used for reconstruction must follow the `Basic` convention that items in
`.args` are themselves `Basic` objects.

I3. Existing public `String` API behavior remains in scope: `.text` is the
Python string supplied by the caller, `String(**String(...).kwargs())`
continues to reconstruct the object, `String` remains atomic for codegen AST
purposes, and string/repr display remains based on the plain text.

I4. Public construction accepts Python `str` text. The internal `Str(text)`
wrapper is accepted only as the reconstruction argument carried in `.args`.
Other text inputs remain invalid.

I5. Default codegen atom collection must continue to treat codegen `String`
objects as leaves rather than exposing the internal reconstruction wrapper.
