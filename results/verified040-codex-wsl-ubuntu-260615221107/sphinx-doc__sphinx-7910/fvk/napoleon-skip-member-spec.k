requires "mini-napoleon.k"

module NAPOLEON-SKIP-MEMBER-SPEC
  imports MINI-NAPOLEON

  // SPEC-PROVENANCE:
  // - I1/I2: A decorated __init__ with functools.wraps keeps __doc__,
  //   __module__, and __qualname__, but its wrapper globals may not contain
  //   the class.  If module+qualname resolves an owner defining the member and
  //   napoleon_include_init_with_doc is true, _skip_member must force include.
  claim <k> skipMember(class, init, true, resolved(true, false), false,
                       cfg(true, false, false))
        => forceInclude </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - I7: The public hint says class decoration has the same issue.  A
  //   resolved wrapper class whose __wrapped__ original owns the member is an
  //   owner candidate.
  claim <k> skipMember(class, init, true, resolved(false, true), false,
                       cfg(true, false, false))
        => forceInclude </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - I4: Nested class paths were already resolved by importing obj.__module__
  //   and walking the dotted qualname.  The V2 helper preserves that behavior.
  claim <k> skipMember(class, private, true, resolved(true, false), false,
                       cfg(false, true, false))
        => forceInclude </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - I4: If module+qualname resolution cannot resolve a top-level class, the
  //   previous obj.__globals__[cls_path] behavior is retained as a fallback.
  claim <k> skipMember(class, special, true, unresolvedTop, true,
                       cfg(false, false, true))
        => forceInclude </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - I5: If the object is not a class/exception owner and not a module member,
  //   Napoleon must not override autodoc's default skip decision.
  claim <k> skipMember(class, init, true, resolved(false, false), false,
                       cfg(true, false, false))
        => default </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - I6: Include-with-doc settings gate the override.  A documented init with
  //   ownership still falls back to autodoc when napoleon_include_init_with_doc
  //   is false.
  claim <k> skipMember(class, init, true, resolved(true, false), false,
                       cfg(false, false, false))
        => default </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - I6: Module-level private/special handling is intentionally independent
  //   from class-owner resolution.
  claim <k> skipMember(module, private, true, unresolvedDotted, false,
                       cfg(false, true, false))
        => forceInclude </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - I6/public tests: __weakref__ is never force-included by this hook.
  claim <k> skipMember(class, weakref, true, resolved(true, true), true,
                       cfg(true, true, true))
        => default </k>
    [all-path]
endmodule
