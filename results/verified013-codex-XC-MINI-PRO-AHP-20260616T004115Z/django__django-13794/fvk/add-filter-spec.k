requires "mini-django-template.k"

module ADD-FILTER-SPEC
  imports MINI-DJANGO-TEMPLATE
  imports INT
  imports BOOL
  imports STRING

  // SPEC-PROVENANCE:
  // - E-3/E-5: documented integer coercion comes before concatenation.
  // - E-6/E-7: text promises are resolved before the documented branch order.
  claim
    <k> add(V:Value, A:Value) => toInt(resolveText(V)) +Int toInt(resolveText(A)) </k>
    requires intable(resolveText(V)) andBool intable(resolveText(A))
    [all-path]

  // SPEC-PROVENANCE:
  // - E-4: if integer coercion fails, the filter attempts native addition.
  claim
    <k> add(V:Value, A:Value) => plusResult(resolveText(V), resolveText(A)) </k>
    requires notBool (intable(resolveText(V)) andBool intable(resolveText(A)))
     andBool plusable(resolveText(V), resolveText(A))
    [all-path]

  // SPEC-PROVENANCE:
  // - E-4: if integer coercion and native addition both fail, return "".
  claim
    <k> add(V:Value, A:Value) => "" </k>
    requires notBool (intable(resolveText(V)) andBool intable(resolveText(A)))
     andBool notBool plusable(resolveText(V), resolveText(A))
    [all-path]

  // SPEC-PROVENANCE:
  // - E-1/E-2: reported failure was str + lazy text proxy returning "".
  // - E-7: gettext_lazy() produces text promises.
  claim
    <k> add(S:String, lazyText(T:String)) => plusResult(S, T) </k>
    requires notBool (intable(S) andBool intable(T))
     andBool plusable(S, T)
    [all-path]

  // SPEC-PROVENANCE:
  // - E-1 says strings with lazy strings; resolving both operands gives
  //   symmetric coverage for lazy text on the left.
  claim
    <k> add(lazyText(S:String), T:String) => plusResult(S, T) </k>
    requires notBool (intable(S) andBool intable(T))
     andBool plusable(S, T)
    [all-path]

  // SPEC-PROVENANCE:
  // - E-5: strings coercible to integers are summed, not concatenated.
  claim
    <k> add(S:String, lazyText(T:String)) => toInt(S) +Int toInt(T) </k>
    requires intable(S) andBool intable(T)
    [all-path]
endmodule

