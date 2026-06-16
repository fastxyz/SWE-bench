// Constructed mini semantics for the directory filtering slice of
// django.template.autoreload. This file was not parsed or machine-checked.

module MINI-AUTORELOAD-SYNTAX
  imports BOOL
  imports STRING
  imports LIST
  imports SET

  syntax Dir ::= EmptyString()
               | Str(String)
               | PathObj(String)
               | DjangoPathObj(String)
               | Invalid()

  syntax Path ::= Cwd()
                | Norm(Path, Dir)

  syntax Bool ::= isEmptyString(Dir) [function]
                | isDjangoTemplatePath(Dir) [function]

  syntax Set ::= collectBackend(List, Path) [function]
               | collectLoader(List, Path) [function]
               | collectAll(List, List, Path) [function]
endmodule

module MINI-AUTORELOAD
  imports MINI-AUTORELOAD-SYNTAX

  rule isEmptyString(EmptyString()) => true
  rule isEmptyString(Str(_)) => false
  rule isEmptyString(PathObj(_)) => false
  rule isEmptyString(DjangoPathObj(_)) => false
  rule isEmptyString(Invalid()) => false

  // Abstract predicate: true exactly for loader-provided Django-internal paths.
  rule isDjangoTemplatePath(EmptyString()) => false
  rule isDjangoTemplatePath(Str(_)) => false
  rule isDjangoTemplatePath(PathObj(_)) => false
  rule isDjangoTemplatePath(DjangoPathObj(_)) => true
  rule isDjangoTemplatePath(Invalid()) => false

  rule collectBackend(.List, CWD) => .Set
  rule collectBackend(ListItem(D) DS, CWD)
    => collectBackend(DS, CWD)
    requires isEmptyString(D)
  rule collectBackend(ListItem(D) DS, CWD)
    => SetItem(Norm(CWD, D)) collectBackend(DS, CWD)
    requires notBool isEmptyString(D)

  rule collectLoader(.List, CWD) => .Set
  rule collectLoader(ListItem(D) DS, CWD)
    => collectLoader(DS, CWD)
    requires isEmptyString(D)
  rule collectLoader(ListItem(D) DS, CWD)
    => collectLoader(DS, CWD)
    requires notBool isEmptyString(D) andBool isDjangoTemplatePath(D)
  rule collectLoader(ListItem(D) DS, CWD)
    => SetItem(Norm(CWD, D)) collectLoader(DS, CWD)
    requires notBool isEmptyString(D) andBool notBool isDjangoTemplatePath(D)

  rule collectAll(BACKEND, LOADER, CWD)
    => collectBackend(BACKEND, CWD) collectLoader(LOADER, CWD)
endmodule
