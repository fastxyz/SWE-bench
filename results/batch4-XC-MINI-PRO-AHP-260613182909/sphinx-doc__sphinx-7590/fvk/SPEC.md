# SPEC.md — formal specification of the V1 fix for sphinx-doc__sphinx-7590

**Subject under verification (SUV):** the C++ user-defined-literal (UDL) support
added to `repo/sphinx/domains/cpp.py` and `repo/sphinx/util/cfamily.py`.

Concretely, four units:

1. `DefinitionParser._parse_literal(self)` — the parse function that turns the
   text at the current parser position into an `ASTLiteral`, **now including
   user-defined literals**.
2. The nested helper `_udl(literal)` inside it.
3. The new AST node `ASTUserDefinedLiteral(literal, ident)` and its three methods
   `_stringify`, `get_id`, `describe_signature`.
4. The three new regexes in `cfamily.py`
   (`integers_literal_suffix_re`, `float_literal_suffix_re`, `udl_identifier_re`)
   plus the new `'udl'` description mode.

This is a **parser**, not an arithmetic loop, so the FVK recipe is applied in its
*case-analysis* form (the **Case Analysis** + **Consequence** rules of
`reachability-and-circularities.md` §2) rather than its *circularity* form: the
function is a finite decision tree over the shape of the input, so an exhaustive
case split **is** a complete proof. There is no data-dependent loop and no
arithmetic VC; the one `for regex in [...]` is a fixed 4-way unrolling (§3 below).

---

## 1. Intent (from `benchmark/PROBLEM.md` + the C++ grammar)

The issue: definitions containing C++ user-defined literals such as

```cpp
inline constexpr auto planck_constant = 6.62607015e-34q_J * 1q_s;
```

fail with `WARNING: Invalid definition: Expected end of definition`. The intended
behavior is that the C++ domain **parses** UDLs the same way it already parses the
other literal forms, so the directive renders instead of warning.

The relevant grammar (C++17 [lex.ext]):

```
user-defined-literal:
    user-defined-integer-literal        # decimal/octal/hex/binary-literal  ud-suffix
    user-defined-floating-point-literal # floating-literal (no float-suffix) ud-suffix
    user-defined-string-literal         # string-literal  ud-suffix
    user-defined-character-literal       # character-literal ud-suffix
ud-suffix: identifier
```

Two facts from the grammar drive the spec:

- **F1.** There is *no* user-defined boolean or pointer literal. `true`, `false`,
  `nullptr` can never carry a ud-suffix.
- **F2.** The ud-suffix is an `identifier` (so: starts with `[A-Za-z_]`, continues
  with `[A-Za-z0-9_]`; **not** a destructor name `~x`, **not** Sphinx's anonymous
  marker `@…`) that **immediately abuts** the literal — no intervening whitespace.
- **F3.** A user-defined-integer / -floating literal carries the ud-suffix
  *instead of* a standard suffix, never in addition to one; but the underlying
  `decimal-literal` / `floating-literal` itself has no standard suffix in the UDL
  production. Equivalently for the parser: consume a standard suffix only when it
  is the *entire* trailing token; otherwise the trailing identifier is the ud-suffix.

---

## 2. Mini-X semantics of the fragment (the trusted base)

The fragment the SUV uses is **regex matching over a string with a cursor**. We
model the parser state and the two primitive operations it relies on. (This stands
in for the "mini-Python" `<k>/<store>` semantics; here the store is the cursor.)

```k
// mini-parser.k  (fragment semantics — constructed, not machine-checked)
module MINI-PARSER
  imports STRING
  imports INT
  imports BOOL

  // Parser configuration: the immutable input and a movable cursor.
  configuration
    <k>   $PGM:K        </k>
    <def> $INPUT:String </def>   // == self.definition (already .strip()ed)
    <pos> 0:Int         </pos>   // == self.pos
    <out> .K            </out>   // the returned AST (or #None)

  // match(R): if regex R matches <def> anchored at <pos>, advance <pos> by the
  // length of the match and yield true; else leave <pos> and yield false.
  //   models BaseParser.match  (cfamily.py: regex.match(self.definition, self.pos))
  rule <k> match(R) => true  ...</k>
       <def> D </def> <pos> P => P +Int len(matchAt(R, D, P)) </pos>
       requires matches(R, D, P)
  rule <k> match(R) => false ...</k>
       <def> D </def> <pos> P </pos>
       requires notBool matches(R, D, P)

  // slice(A,B) == self.definition[A:B]
  rule <k> slice(A, B) => substr(D, A, B) ...</k> <def> D </def>
endmodule
```

`matches`, `matchAt`, `substr`, `len` are the **trusted primitives** — they stand
for Python's `re` engine and string slicing. The proof reasons about *which* regex
matches at a position, using the regex definitions as axioms (§ Appendix A). This
is the analogue of trusting K's `+Int`. Residual risk from this trust is recorded
in `PROOF.md` §Residual.

---

## 3. Function contract — `_parse_literal`

`_parse_literal` is a partial function `Parser → ASTLiteral ∪ {None}` with the
side effect of advancing `<pos>`. Write `s` for the input suffix `D[P:]` (the text
from the cursor onward, after `skip_ws`). The contract is a **reachability rule**
`φ_pre ⇒ φ_post`, given here as a table of disjoint cases (Case Analysis). Let

- `NUMlit` = the maximal prefix of `s` matched by `float_literal_re`, else by one
  of `binary/hex/integer/octal_literal_re` (in that order);
- `INTSUF`/`FLTSUF` = `integers_literal_suffix_re` / `float_literal_suffix_re`;
- `UD` = `udl_identifier_re`;
- `id(t)` = the maximal `UD`-match at the position after a token `t`.

```
(LIT) claim:
  <k> _parse_literal() => RESULT </k>  <pos> P0 => P1 </pos>
  requires  P0 == position-after-skip_ws

  CASE B  (boolean/pointer):  s starts with a whole word in {nullptr,true,false}
          ⇒ RESULT ∈ {ASTPointerLiteral, ASTBooleanLiteral(b)},  P1 = P0+len(word)
          and NO ud-suffix is ever attached            [grammar fact F1]

  CASE F  (floating):  float_literal_re matches s, yielding NUMlit
       F1 if FLTSUF matches at P0+|NUMlit| (a *complete* float suffix):
              RESULT = ASTNumberLiteral(NUMlit·suf),  P1 advanced past suf
       F2 else if UD matches at P0+|NUMlit|:
              RESULT = ASTUserDefinedLiteral(ASTNumberLiteral(NUMlit), id),
              P1 advanced past the ud-suffix
       F3 else: RESULT = ASTNumberLiteral(NUMlit),  P1 = P0+|NUMlit|

  CASE I  (integer family: binary, hex, decimal, octal — first match wins):
       symmetric to CASE F with INTSUF in place of FLTSUF

  CASE S  (string):  _parse_string() returns a quoted string str
       ⇒ RESULT = _udl(ASTStringLiteral(str))      (UDL iff a ud-suffix abuts it)

  CASE C  (character):  char_literal_re matches
       ⇒ build ASTCharLiteral; on decode error -> fail() (raises);
         otherwise RESULT = _udl(ASTCharLiteral(prefix,data))

  CASE N  (none of the above):  RESULT = None,  P1 = P0
```

**Postcondition invariants (must hold in every case):**

- **PC-ROUNDTRIP.** `str(RESULT) == D[P0:P1]` whenever `RESULT ≠ None` and the input
  was well-formed C++ — i.e. the parser consumes *exactly* the characters of the
  literal it returns. (For UDLs: `str = str(literal)+str(ident) = NUMlit+suffix`.)
- **PC-PROGRESS.** `RESULT ≠ None ⇒ P1 > P0` (at least one char consumed). Dually
  `RESULT = None ⇒ P1 = P0` (no spurious cursor movement on a non-literal).
- **PC-NOWS.** A ud-suffix is attached **iff** an identifier abuts the literal with
  no whitespace between (helper `_udl` does not `skip_ws`). [F2]
- **PC-NOBOOLUDL.** Cases B never produce a UDL. [F1]
- **PC-STDSUFFIX.** In F/I, a standard suffix is consumed (no UDL) **iff** it is the
  complete trailing token (regex ends in `\b`); a numeric literal that abuts more
  identifier characters becomes a UDL, not a number-with-stray-text. [F3]
- **PC-TOTAL.** `_parse_literal` never raises except via the pre-existing
  `self.fail(...)` on an undecodable character literal (Case C); in particular the
  UDL path adds no new exception.

---

## 4. Method contracts — `ASTUserDefinedLiteral`

Let `U = ASTUserDefinedLiteral(L, I)` with `L : ASTLiteral`, `I : ASTIdentifier`.

- **`_stringify(t)` :** `= t(L) ++ t(I)`. Contract **STR**: `str(U) = str(L)+str(I)`
  and `display(U) = display(L)+display(I)`. (Used by PC-ROUNDTRIP.)

- **`get_id(v)` :** `= "clL_Zli" ++ I.get_id(v) ++ "E" ++ L.get_id(v) ++ "E"`.
  Contract **ID**: this is exactly the Itanium-ABI mangling of the *call*
  `operator"" <suffix>(<literal>)`:
  - `cl … E` is the function-call production (identical to
    `ASTPostfixCallExpr.get_id`, cpp.py:1084, `['cl', idPrefix, args…, 'E']`);
  - the callee `L_Zli<I.get_id>E` is the `expr-primary` external-name form
    `L <mangled-name> E` with mangled-name `_Z li<source-name>`, where
    `li<source-name>` is exactly `ASTOperatorLiteral.get_id` (cpp.py:1589);
  - the single argument is `L.get_id(v)` (the literal already self-wraps, e.g.
    `L1E`).
  Required properties:
  - **ID-DET** deterministic (pure function of `L`,`I`,`v`);
  - **ID-INJ** injective up to literal-equality: `get_id(U1)=get_id(U2) ⇒ U1≡U2`,
    because `I.get_id` is prefix-free (`<len><name>`) and `L.get_id` self-delimits
    (`L…E`); so the suffix and the literal can be read back unambiguously;
  - **ID-NOCLASH** the only non-UDL expression that can share this id is a literal
    operator call `operator"" suffix(literal)`, which *is* the same entity — so no
    spurious cross-reference collision.
  - **Domain note (ID-DOMAIN):** in `cpp.py` an expression's `get_id` is reached
    **only for id-version ≥ 3** — `ASTTemplateArgConstant.get_id` (cpp.py:1643)
    and `ASTArray.get_id` (cpp.py:2133) both emit `str(self)` for versions 1–2 and
    call `self.value.get_id(v)` only for `v ≥ 3`. So the `v` argument here is
    effectively always ≥ 3; versions 1–2 use **STR** instead. (See FINDING 5.)

- **`describe_signature(signode, mode, env, symbol)` :** appends
  `L.describe_signature(signode, mode, …)` then
  `I.describe_signature(signode, "udl", …)`. Contract **DESC**: renders the visible
  text `str(L)+str(I)` and never emits a `pending_xref` for the suffix (the
  ud-suffix names a literal operator, not a referenceable identifier). Requires the
  `'udl'` mode to be a legal description mode (added to `verify_description_mode`
  and handled in `ASTIdentifier.describe_signature`).

---

## Appendix A — regex axioms used by the proof

```
float_literal_re            : decimal/hex floating forms (needs '.', 'e/E', or 'p/P').
integer_literal_re          : [1-9][0-9]*
octal_literal_re            : 0[0-7]*
hex_literal_re              : 0[xX][0-9a-fA-F]+
binary_literal_re           : 0[bB][01]+
float_literal_suffix_re     : [fFlL](?![A-Za-z0-9_])         # exactly one f/F/l/L, then a non-ident char
integers_literal_suffix_re  : (u/l/ll combinations, only one 'u') ... \b
udl_identifier_re           : [A-Za-z_][A-Za-z0-9_]*\b       # no '~', no '@'
```

Key lemma used repeatedly (**LEM-\b**): because every standard-suffix character
(`u U l L f F`) is itself a `\w` (word) character, the trailing `\b` on
`integers_literal_suffix_re` (and the `(?![A-Za-z0-9_])` on
`float_literal_suffix_re`) fails exactly when another identifier character follows
the candidate suffix. Hence "standard suffix matched" ⟺ "the suffix is the whole
trailing token", which is precisely PC-STDSUFFIX / grammar fact F3.
