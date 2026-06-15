requires "domains.md"

module MINI-PYTHON-SYNTAX
  imports INT
  imports BOOL
  imports STRING

  syntax Rel ::= rnil()
               | rcons(Int, Rel)

  syntax Version ::= numeric(Rel, String)
                   | nonnumeric(String)

  syntax ModuleArg ::= moduleWithVersion(Version)
                     | missingImport()
                     | invalidModule()

  syntax LV ::= lv(Rel)
              | lvOther(String)

  syntax Outcome ::= ok(Bool)
                   | valueError()
                   | typeError()

  syntax Outcome ::= minversion(ModuleArg, Version, Bool) [function]
  syntax LV ::= normalize(Version) [function]
  syntax Outcome ::= compare(LV, LV, Bool) [function]
  syntax Bool ::= looseGe(Rel, Rel) [function]
  syntax Bool ::= looseGt(Rel, Rel) [function]
  syntax Bool ::= relEq(Rel, Rel) [function]
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX

  configuration <k> $PGM:Outcome </k>

  rule normalize(numeric(R, _Suffix)) => lv(R)
  rule normalize(nonnumeric(S)) => lvOther(S)

  rule minversion(missingImport(), _Required, _Inclusive) => ok(false)
  rule minversion(invalidModule(), _Required, _Inclusive) => valueError()
  rule minversion(moduleWithVersion(Have), Required, Inclusive)
    => compare(normalize(Have), normalize(Required), Inclusive)

  rule compare(lv(H), lv(R), true) => ok(looseGe(H, R))
  rule compare(lv(H), lv(R), false) => ok(looseGt(H, R))
  rule compare(lvOther(_), _, _) => typeError()
  rule compare(_, lvOther(_), _) => typeError()

  rule relEq(rnil(), rnil()) => true
  rule relEq(rnil(), rcons(_, _)) => false
  rule relEq(rcons(_, _), rnil()) => false
  rule relEq(rcons(H, HT), rcons(R, RT)) => (H ==Int R) andBool relEq(HT, RT)

  rule looseGe(rnil(), rnil()) => true
  rule looseGe(rnil(), rcons(_, _)) => false
  rule looseGe(rcons(_, _), rnil()) => true
  rule looseGe(rcons(H, _HT), rcons(R, _RT)) => true requires H >Int R
  rule looseGe(rcons(H, _HT), rcons(R, _RT)) => false requires H <Int R
  rule looseGe(rcons(H, HT), rcons(R, RT)) => looseGe(HT, RT) requires H ==Int R

  rule looseGt(H, R) => looseGe(H, R) andBool notBool relEq(H, R)
endmodule
