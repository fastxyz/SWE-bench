# Intent Spec

Constructed, not machine-checked.

The public issue requires the Python-domain index entry for `py:method` with
the `:property:` option to be formatted as a property, not as a callable method.

Required behavior:

1. For a qualified method name such as `Foo.bar`, `PyMethod.get_index_text()`
   with `property in self.options` returns property-shaped text equivalent to
   `bar (Foo property)`, with no `()` after `bar`.
2. The same property-option rule applies regardless of other method-like flags
   such as `:classmethod:` or `:staticmethod:` because the observable defect is
   caused by the presence of `:property:`.
3. For unqualified names, a property-option index entry must also avoid callable
   parentheses and match the existing `PyProperty` module/no-module shape.
4. Non-property method, classmethod, and staticmethod index entries retain their
   callable `()` formatting.
5. The fix must not change signature rendering, object registration, node ids,
   cross-reference roles, or the `add_target_and_index()` append protocol.

Observed legacy behavior to check, not preserve:

- The public test at `repo/tests/test_domain_py.py:758` expects
  `meth5() (Class property)`. Under the FVK SUSPECT rule, that assertion encodes
  the behavior reported as buggy and cannot veto the issue-derived intent.
