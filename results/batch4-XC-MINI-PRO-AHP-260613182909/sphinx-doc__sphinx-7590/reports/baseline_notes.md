# Baseline notes — sphinx-doc__sphinx-7590

## Issue

The C++ domain fails to parse **user-defined literals (UDLs)**. A definition such as

```cpp
namespace units::si {
inline constexpr auto planck_constant = 6.62607015e-34q_J * 1q_s;
}
```

produces

```
WARNING: Invalid definition: Expected end of definition. [error at 58]
```

UDLs are a number/string/character literal immediately followed by a *ud-suffix*
(an identifier with no intervening whitespace), e.g. `6.62607015e-34q_J` is the
floating literal `6.62607015e-34` with ud-suffix `q_J`, and `1q_s` is the integer
literal `1` with ud-suffix `q_s`.

## Root cause

`Parser._parse_literal` in `sphinx/domains/cpp.py` recognised the literal grammar
listed in its own docstring **except** the final alternative, `user-defined-literal`
— the method body literally ended with `# TODO: user-defined lit`.

Concretely, for a number literal it matched the numeric regex and then greedily
consumed only the standard suffix characters `uUlLfF`:

```python
if self.match(regex):
    while self.current_char in 'uUlLfF':
        self.pos += 1
    return ASTNumberLiteral(self.definition[pos:self.pos])
```

So for `1q_s` it matched `1`, stopped at `q` (not a standard suffix), and returned
`ASTNumberLiteral("1")`. The leftover `q_s` then could not be consumed by the
expression grammar, so the parser reported "Expected end of definition". String and
character literals had the same gap (no ud-suffix handling at all).

## Fix

Added parsing and an AST node for user-defined literals, and tightened how the
trailing standard suffix of a numeric literal is recognised so that a ud-suffix is
not mistaken for (or swallowed by) a standard suffix.

### `sphinx/util/cfamily.py`

* New regexes used by the C++ parser:
  * `integers_literal_suffix_re` — matches a *complete* integer suffix
    (`u`/`l`/`ll` combinations, only one `u`). Negative look-aheads `(?![uUlL])`
    plus a trailing `\b` ensure it only matches when the suffix is the whole token;
    if more identifier characters follow, the match fails and the token is treated
    as a UDL instead. This is what lets `1ull` stay a plain number while `1q_s`
    becomes a UDL.
  * `float_literal_suffix_re` — matches a single float suffix `f`/`F`/`l`/`L`, but
    only when not followed by another identifier character (`(?![a-zA-Z0-9_])`), so
    `1.0f` stays a plain float while `1.0_f` becomes a UDL.
  * `udl_identifier_re` — the ud-suffix grammar: a plain identifier
    (`[a-zA-Z_][a-zA-Z0-9_]*`), deliberately excluding `~` (destructor names) and
    `@` (Sphinx's anonymous-entity marker), since neither can be a ud-suffix.
* `verify_description_mode` now also accepts the new `'udl'` description mode
  (see below).

### `sphinx/domains/cpp.py`

* Imported the three new regexes from `cfamily`.
* New AST node `ASTUserDefinedLiteral(literal, ident)`:
  * `_stringify` renders the literal followed by the suffix, e.g. `1q_s`, so the
    signature round-trips exactly.
  * `get_id` mangles the UDL the way the language defines it — as a call to the
    literal operator, `operator"" <suffix>(<literal>)`. Using the existing building
    blocks (`ASTOperatorLiteral` mangles `operator"" X` as `li<source-name>`, and
    `ASTNumberLiteral`/etc. already mangle their argument), the call expression is
    `clL_Zli{ident-id}E{literal-id}E`. For `1q_s` (v2+) this yields
    `clL_Zli3q_sEL1EE`, which is unique and stable for cross-referencing.
  * `describe_signature` renders the literal normally and then the suffix.
* `ASTIdentifier.describe_signature` gained a `'udl'` mode that renders the
  identifier as plain text. The ud-suffix names a literal operator
  (`operator"" _x`), not a referenceable identifier on its own, so emitting a
  `pending_xref` for it (as `markType` would) would create a bogus, unresolvable
  cross-reference. Plain text avoids that while still showing the suffix.
* Rewrote `_parse_literal`:
  * Added a nested helper `_udl(literal)` that, with **no** whitespace skipping,
    tries to match a ud-suffix immediately after a parsed literal and, if present,
    wraps it in `ASTUserDefinedLiteral`.
  * The floating-point branch is handled separately from the integer family so each
    can use its own (correct) standard-suffix regex; in both cases, when no standard
    suffix is present, `_udl` is consulted.
  * String and character literals are now also passed through `_udl`.
  * The closing `# TODO: user-defined lit` comment was removed.

### `CHANGES`

* Added a "Features added" entry: "#7590: C++, parse user-defined literals."

## Assumptions / alternatives considered

* **ID mangling format.** I modelled the UDL's `get_id` on the Itanium ABI: a UDL is
  semantically a call to its literal operator, so it mangles as a function-call
  expression `cl … E` whose callee is the `expr-primary` of the literal operator
  (`L _Z li<source-name> E`) and whose single argument is the literal. The exact
  parameter type of the operator is not derivable from an expression, so (as Sphinx
  already does elsewhere) only the operator name is encoded. The result is
  deterministic and collision-free, which is all the cross-reference machinery needs.
  Alternatives such as treating the whole token as an opaque string (like
  `ASTNumberLiteral`) were rejected because they would not distinguish the suffix in
  IDs and would diverge from how the rest of the expression grammar is mangled.

* **Distinguishing standard suffixes from ud-suffixes.** The original code's greedy
  `uUlLfF` consumption is ambiguous: e.g. it would split `123foo` into `123f` + `oo`.
  I replaced it with explicit suffix regexes anchored by `\b`/negative look-ahead so
  a standard suffix only matches when it is the *entire* trailing token; otherwise
  the trailing identifier is treated as a ud-suffix. This keeps every existing plain
  literal (`1ull`, `1.0f`, `0x1p0`, …) unchanged while enabling UDLs. The issue's own
  suffixes (`q_J`, `q_s`) start with characters outside the standard-suffix sets, so
  they were never at risk of mis-splitting, but handling the general case correctly
  is cheap and avoids surprising results.

* **ud-suffix must be adjacent.** Per the grammar a ud-suffix directly abuts the
  literal, so `_udl` intentionally does *not* call `skip_ws()` before matching the
  identifier; `1 q_s` (with a space) is therefore not a UDL.

* **Scope = C++ only.** UDLs are a C++ feature, so `sphinx/domains/c.py`'s separate
  `_parse_literal` was deliberately left untouched; adding UDL parsing there would be
  incorrect for the C language.

* **Keywords as suffixes.** Standard C++ forbids most identifiers that collide with
  keywords as ud-suffixes, but enforcing that adds complexity with no documentation
  benefit, so `_udl` accepts any identifier (a documentation tool should be lenient).
