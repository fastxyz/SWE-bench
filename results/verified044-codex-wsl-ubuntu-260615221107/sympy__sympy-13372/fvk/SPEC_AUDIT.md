# Spec Audit

Status: pass, constructed but not machine-checked.

1. Intent: no `UnboundLocalError` for the reported reversed `Mul`.
   Formal English: symbolic nonzero components reach `notImplemented`, not tuple
   assembly.
   Result: pass.

2. Intent: preserve unevaluable symbolic factors.
   Formal English: symbolic nonzero components are not converted into exact-zero
   sentinels or malformed numeric tuples; public evalf fallback reconstructs
   symbolically.
   Result: pass.

3. Intent: respect evalf tuple shape.
   Formal English: successful tuples only contain mpf-valued components or
   exact-zero sentinels.
   Result: pass.

4. Intent: reject the ambiguous `prec=None`-only alternative.
   Formal English: precision `None` alone is insufficient; the symbolic
   component must not be present in a successful tuple.
   Result: pass.

5. Intent: preserve public compatibility.
   Formal English: no public signature or override protocol changes.
   Result: pass.

No required behavior is marked fail or ambiguous.
