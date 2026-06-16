requires "mini-sphinx-glossary.k"

module SPHINX-GLOSSARY-SPEC
  imports MINI-SPHINX-GLOSSARY

  syntax Label ::= LMYSQL_UPPER() [function]
                 | LMYSQL_LOWER() [function]

  rule LMYSQL_UPPER() => label("glossary", "term-MySQL") [simplification]
  rule LMYSQL_LOWER() => label("glossary", "term-mysql") [simplification]

  rule norm("MySQL") => "MySQL" [simplification]
  rule norm("mysql") => "mysql" [simplification]
  rule norm("MYSQL") => "MYSQL" [simplification]
  rule lower("MySQL") => "mysql" [simplification]
  rule lower("mysql") => "mysql" [simplification]
  rule lower("MYSQL") => "mysql" [simplification]

  // SPEC-PROVENANCE:
  // - E-001/E-002: the issue reports MySQL/mysql as distinct glossary terms.
  // - E-006: term objects are exposed through the standard-domain object map.
  claim [CASE-DISTINCT-REGISTRATION]:
    <k> registerTerm("MySQL", LMYSQL_UPPER())
        ~> registerTerm("mysql", LMYSQL_LOWER()) => .K ... </k>
    <objects> .Map => putTerm(putTerm(.Map, "MySQL", LMYSQL_UPPER()),
                              "mysql", LMYSQL_LOWER()) </objects>
    <warnings> .List => .List </warnings>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-003: exact duplicate terms still warn.
  claim [EXACT-DUPLICATE-WARNS]:
    <k> registerTerm("mysql", LMYSQL_LOWER())
        ~> registerTerm("mysql", LMYSQL_UPPER()) => .K ... </k>
    <objects> .Map => putTerm(putTerm(.Map, "mysql", LMYSQL_LOWER()),
                              "mysql", LMYSQL_UPPER()) </objects>
    <warnings> .List => ListItem(duplicate("mysql")) </warnings>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-004: preserve lowercased reftarget while carrying exact original spelling.
  claim [TERM-ROLE-COMPAT-SHAPE]:
    <k> makeTermRef("MySQL") => .K ... </k>
    <result> none => xref("mysql", "MySQL") </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-002/E-004: exact local resolution distinguishes case variants even
  //   though the compatibility reftarget is lowercased.
  claim [EXACT-TERM-RESOLUTION]:
    <k> resolveNode(xref("mysql", "MySQL")) => .K ... </k>
    <objects> putTerm(putTerm(.Map, "MySQL", LMYSQL_UPPER()),
                      "mysql", LMYSQL_LOWER()) </objects>
    <result> none => some(LMYSQL_UPPER()) </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-005: keep unambiguous historical case-insensitive lookup.
  claim [UNAMBIGUOUS-FOLD-FALLBACK]:
    <k> resolveTerm("MYSQL") => .K ... </k>
    <objects> putTerm(.Map, "MySQL", LMYSQL_UPPER()) </objects>
    <result> none => some(LMYSQL_UPPER()) </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-002/E-005: do not guess when case-folded terms are genuinely distinct.
  claim [AMBIGUOUS-FOLD-REFUSES-GUESS]:
    <k> resolveTerm("MYSQL") => .K ... </k>
    <objects> putTerm(putTerm(.Map, "MySQL", LMYSQL_UPPER()),
                      "mysql", LMYSQL_LOWER()) </objects>
    <result> none => none </result>
    [all-path]
endmodule
