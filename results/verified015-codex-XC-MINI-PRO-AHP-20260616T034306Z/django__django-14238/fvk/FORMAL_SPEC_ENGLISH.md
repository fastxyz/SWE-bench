# Formal Specification In English

Each entry paraphrases a K claim in `fvk/autofield-meta-spec.k`.

- O1: Any class that inherits from `BigAutoField` satisfies
  `autoFieldSubclassCheck(C)`.
- O2: Any class that inherits from `SmallAutoField` satisfies
  `autoFieldSubclassCheck(C)`.
- O3: Any class that inherits directly from `AutoField` satisfies
  `autoFieldSubclassCheck(C)` through the `super()` fallback.
- O4: A class outside the `AutoField`, `BigAutoField`, and `SmallAutoField`
  inheritance families does not satisfy `autoFieldSubclassCheck(C)`.
- O5: A custom `BigAutoField` subclass is accepted by default primary-key
  validation.
- O6: A custom `SmallAutoField` subclass is accepted by default primary-key
  validation.
- O7: An indirect custom `BigAutoField` subclass is accepted by default
  primary-key validation.
- O8: `textField` is rejected by default primary-key validation.
- O9: import failure and empty-path inputs remain `ImproperlyConfigured`.
- O10: the legacy exact-membership rule rejects a custom `BigAutoField`
  subclass, reconstructing the reported bug.
