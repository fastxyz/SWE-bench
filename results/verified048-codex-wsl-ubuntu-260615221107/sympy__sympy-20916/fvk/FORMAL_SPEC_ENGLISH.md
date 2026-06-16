# Formal Spec In English

1. If the first name part is a non-empty sequence of Unicode word characters
   that are not digits and not underscore, followed by a non-empty sequence of
   ASCII digits, then the trailing digits are inserted as the first subscript.
2. A Greek letter such as `ω` qualifies as a base character in that rule.
3. Digits do not qualify as base characters, so `x10` captures suffix `10`
   rather than only `0`.
4. Underscore does not qualify as a base character for the implicit rule;
   explicit underscore parsing remains handled by the existing scan.
5. If the subscript list contains ASCII digit strings, unicode pretty printing
   renders them with the corresponding Unicode subscript characters.
6. The proof is constructed only; machine verification requires the emitted
   `kompile`, `kast`, and `kprove` commands.
