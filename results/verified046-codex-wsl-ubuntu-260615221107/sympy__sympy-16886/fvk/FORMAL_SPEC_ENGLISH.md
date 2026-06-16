# Formal Spec In English

This paraphrases the K claims in `fvk/morse-spec.k`.

1. `(MORSE-TABLE-ONE)`: the default Morse decode table maps `.----` to `"1"`.
2. `(MORSE-INVERSE-ONE)`: reversing the default decode table produces a default
   encode table where `"1"` maps to `.----`.
3. `(ENCODE-ONE)`: evaluating the default one-character encode path on `"1"`
   returns `.----`.
4. `(DECODE-ONE)`: evaluating the default one-token decode path on `.----`
   returns `"1"`.
5. `(DIGIT-FAMILY)`: the digit entries `0` through `9` match the standard Morse
   digit family exactly; in that exact digit table, `----` is not the key for
   `"1"`.
