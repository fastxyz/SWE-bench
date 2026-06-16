// Constructed, not machine-checked.
// Mini semantics for the observable branch behavior of PyMethod.get_index_text().
// The model keeps the property under verification explicit: whether the index
// text is property-shaped without callable parentheses or method-shaped with
// callable parentheses.

module MINI-PYTHON-DOMAIN-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax NameShape ::= qualified(String, String)
                     | unqualified(String)

  syntax ModName ::= noMod
                   | mod(String)

  // opts(property, classmethod, staticmethod)
  syntax Options ::= opts(Bool, Bool, Bool)

  syntax IndexText ::= propertyClass(String, String)
                     | propertyModule(String, String)
                     | propertyPlain(String)
                     | methodClass(String, String)
                     | classMethodClass(String, String)
                     | staticMethodClass(String, String)
                     | methodModule(String, String)
                     | methodPlain(String)

  syntax String ::= joinMod(String, String) [function]
  syntax String ::= displayClass(ModName, Bool, String) [function]
  syntax IndexText ::= getIndexText(Options, ModName, Bool, NameShape) [function]
  syntax Bool ::= hasCallableParens(IndexText) [function]
endmodule

module MINI-PYTHON-DOMAIN
  imports MINI-PYTHON-DOMAIN-SYNTAX

  configuration <k> $PGM:K </k>

  rule joinMod(MOD:String, CLS:String) => MOD +String "." +String CLS

  rule displayClass(noMod, ADD:Bool, CLS:String) => CLS
  rule displayClass(mod(MOD:String), true, CLS:String) => joinMod(MOD, CLS)
  rule displayClass(mod(MOD:String), false, CLS:String) => CLS

  // Property option wins over callable method variants.
  rule getIndexText(opts(true, CM:Bool, SM:Bool), MOD:ModName, ADD:Bool,
                    qualified(CLS:String, METH:String))
    => propertyClass(METH, displayClass(MOD, ADD, CLS))

  rule getIndexText(opts(true, CM:Bool, SM:Bool), mod(MOD:String), ADD:Bool,
                    unqualified(NAME:String))
    => propertyModule(NAME, MOD)

  rule getIndexText(opts(true, CM:Bool, SM:Bool), noMod, ADD:Bool,
                    unqualified(NAME:String))
    => propertyPlain(NAME)

  // Non-property method cases retain callable method-shaped entries.
  rule getIndexText(opts(false, true, SM:Bool), MOD:ModName, ADD:Bool,
                    qualified(CLS:String, METH:String))
    => classMethodClass(METH, displayClass(MOD, ADD, CLS))

  rule getIndexText(opts(false, false, true), MOD:ModName, ADD:Bool,
                    qualified(CLS:String, METH:String))
    => staticMethodClass(METH, displayClass(MOD, ADD, CLS))

  rule getIndexText(opts(false, false, false), MOD:ModName, ADD:Bool,
                    qualified(CLS:String, METH:String))
    => methodClass(METH, displayClass(MOD, ADD, CLS))

  rule getIndexText(opts(false, CM:Bool, SM:Bool), mod(MOD:String), ADD:Bool,
                    unqualified(NAME:String))
    => methodModule(NAME, MOD)

  rule getIndexText(opts(false, CM:Bool, SM:Bool), noMod, ADD:Bool,
                    unqualified(NAME:String))
    => methodPlain(NAME)

  rule hasCallableParens(propertyClass(METH:String, CLS:String)) => false
  rule hasCallableParens(propertyModule(NAME:String, MOD:String)) => false
  rule hasCallableParens(propertyPlain(NAME:String)) => false
  rule hasCallableParens(methodClass(METH:String, CLS:String)) => true
  rule hasCallableParens(classMethodClass(METH:String, CLS:String)) => true
  rule hasCallableParens(staticMethodClass(METH:String, CLS:String)) => true
  rule hasCallableParens(methodModule(NAME:String, MOD:String)) => true
  rule hasCallableParens(methodPlain(NAME:String)) => true
endmodule
