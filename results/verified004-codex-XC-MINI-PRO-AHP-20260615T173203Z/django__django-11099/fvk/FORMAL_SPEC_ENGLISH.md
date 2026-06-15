# Formal Spec English

This file paraphrases the nontrivial claims in `username-validator-spec.k`.

C-001: For any character list `CS`, `validate(asciiUsername, CS)` returns `valid` if `CS` is non-empty and every character category in `CS` is allowed by the ASCII username validator.

C-002: For any character list `CS`, `validate(asciiUsername, CS)` returns `invalid` if `CS` is empty or at least one character category in `CS` is not allowed by the ASCII username validator.

C-003: For any character list `CS` containing only ASCII-allowed username characters, `validate(asciiUsername, appendLF(CS))` returns `invalid`. In plain Python terms, appending a final `\n` to an otherwise valid ASCII username makes it invalid.

C-004: For any character list `CS`, `validate(unicodeUsername, CS)` returns `valid` if `CS` is non-empty and every character category in `CS` is allowed by the Unicode username validator.

C-005: For any character list `CS`, `validate(unicodeUsername, CS)` returns `invalid` if `CS` is empty or at least one character category in `CS` is not allowed by the Unicode username validator.

C-006: For any character list `CS` containing only Unicode-allowed username characters, `validate(unicodeUsername, appendLF(CS))` returns `invalid`. In plain Python terms, appending a final `\n` to an otherwise valid Unicode username makes it invalid.

C-007: The model distinguishes passing and failing cases on the property under audit: `cons(asciiWord, .Chars)` maps to `valid`, while `appendLF(cons(asciiWord, .Chars))` maps to `invalid`.
