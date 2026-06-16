# Proof

Status: constructed, not machine-checked. No tests, Python code, `kompile`, or
`kprove` were run.

## Claims proved in the constructed model

1. `DECIMAL-PRESERVE`: Decimal input `D` and normalized integer places `P`
   reach `render(D, P)`.
2. `ISSUE-DECIMAL-20`: the issue value
   `dec(0, 4212345678901234567890, 20)` with places `20` reaches
   `rendered("42.12345678901234567890")`.
3. `NONDECIMAL-FRAME`: non-Decimal input still reaches rendering through
   `decimalFromRepr(R)`, the modeled old branch.
4. `INVALID-ARG-DECIMAL-DISPLAY`: Decimal invalid-argument fallback returns the
   Decimal display path, matching V1's `input_val = str(text)`.

## Symbolic proof sketch

For `DECIMAL-PRESERVE`, the mini semantics has exactly one rule matching
`floatformat(decimal(D), places(P))`:

```k
rule <k> floatformat(decimal(D:Dec), places(P:Int)) => render(D, P) ... </k>
```

By Axiom plus framing, the starting configuration rewrites directly to the
post-configuration. No case split or loop circularity is needed because the
audited conversion slice has no loop.

For `ISSUE-DECIMAL-20`, first apply the Decimal-preserve rule with
`D = dec(0, 4212345678901234567890, 20)` and `P = 20`. Then apply the concrete
rendering simplification:

```k
rule render(dec(0, 4212345678901234567890, 20), 20)
  => rendered("42.12345678901234567890")
```

By Transitivity, the original state reaches the expected rendered string.

For `NONDECIMAL-FRAME`, the only matching non-Decimal rule is:

```k
rule <k> floatformat(nondecimal(R:String), places(P:Int))
  => render(decimalFromRepr(R), P) ... </k>
```

That is the modeled frame condition for the source diff: V1 did not change the
non-Decimal branch.

For `INVALID-ARG-DECIMAL-DISPLAY`, the invalid-argument rule rewrites to
`original(decimal(D))`. This records the consequence of using `str(text)` as
`input_val` for Decimal inputs. The adequacy audit marks this as compatible but
not part of the core precision proof.

## Why V1 stands

The pre-fix symbolic route for Decimal input was:

```text
repr(Decimal D) -> Decimal("Decimal('...')") fails
                 -> Decimal(str(float(D))) -> lossy Df
                 -> render(Df, P)
```

The V1 symbolic route is:

```text
isinstance(text, Decimal) -> d = text -> render(D, P)
```

That removes the only conversion step identified by the public issue as the
precision loss source. The rest of the function, including suffix parsing,
quantization, digit rendering, and localization delegation, is unchanged.

## Reproduce the machine check later

These commands are emitted for a real environment. They were not run here.

```sh
kompile fvk/mini-floatformat.k --backend haskell
kast --backend haskell fvk/floatformat-spec.k
kprove fvk/floatformat-spec.k
```

Expected machine-check result in a real K environment: all claims reduce to
`#Top`.

## Test guidance

Do not delete tests based on this constructed proof. A public regression test
for the issue point would be useful, but this task forbids modifying tests.
Existing localization, grouping, SafeString, infinity/NaN, and low-context
Decimal tests should remain because the mini model intentionally abstracts
those integration details.
