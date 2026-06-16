module MINI-PYLINT-DISCOVERY-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax PathList ::= ".PathList"
                    | cons(Path, PathList)
  syntax FsList ::= ".FsList"
                  | Fs ";" FsList
  syntax Fs ::= file(Path, Bool)
              | dir(Path, Bool, FsList)
  syntax IgnoreConfig ::= noIgnore
                        | ignoreName(Path)
                        | ignorePath(Path)

  syntax Path ::= String
  syntax PathList ::= discover(FsList, IgnoreConfig) [function]
                    | discoverChildren(FsList, IgnoreConfig) [function]
  syntax Bool ::= ignored(Path, IgnoreConfig) [function]
                | isPy(Path) [function]
  syntax Path ::= norm(Path) [function]
  syntax KResult ::= PathList | Bool | Path
endmodule

module MINI-PYLINT-DISCOVERY
  imports MINI-PYLINT-DISCOVERY-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:PathList </k>

  // Abstract helpers. These model the properties used by the Python code:
  // ignoreName is basename matching; ignorePath matches raw or normalized path.
  rule ignored(P, noIgnore) => false
  rule ignored(P, ignoreName(N)) => basenameMatches(P, N)
  rule ignored(P, ignorePath(N)) => pathMatches(P, N) orBool pathMatches(norm(P), N)

  syntax Bool ::= basenameMatches(Path, Path) [function]
  syntax Bool ::= pathMatches(Path, Path) [function]
  syntax Path ::= basename(Path) [function]

  // Concrete matcher facts used by the spec claims.
  rule basenameMatches(".a", ".a") => true
  rule basenameMatches("./.a", ".a") => true
  rule basenameMatches(".#lock.py", ".#lock.py") => true
  rule basenameMatches("bar.py", ".#lock.py") => false
  rule pathMatches("./.a", ".a") => false
  rule pathMatches(".a", ".a") => true
  rule norm("./.a") => ".a"

  // Empty traversal yields no paths.
  rule discover(.FsList, I) => .PathList
  rule discoverChildren(.FsList, I) => .PathList

  // Ignored files and directories are skipped. For directories this represents
  // top-down pruning: children are not discovered.
  rule discover(file(P, ISPY) ; REST, I) => discover(REST, I)
    requires ignored(P, I) ==Bool true
  rule discover(dir(P, HASINIT, CHILDREN) ; REST, I) => discover(REST, I)
    requires ignored(P, I) ==Bool true

  // A package directory is yielded once. Its children are not walked by this
  // discovery pass because expand_modules expands the package.
  rule discover(dir(P, true, CHILDREN) ; REST, I) => cons(P, discover(REST, I))
    requires ignored(P, I) ==Bool false

  // A non-package directory recursively discovers its children and then siblings.
  rule discover(dir(P, false, CHILDREN) ; REST, I) =>
       append(discoverChildren(CHILDREN, I), discover(REST, I))
    requires ignored(P, I) ==Bool false

  // Unignored Python files are yielded; non-Python files are skipped.
  rule discover(file(P, true) ; REST, I) => cons(P, discover(REST, I))
    requires ignored(P, I) ==Bool false
  rule discover(file(P, false) ; REST, I) => discover(REST, I)
    requires ignored(P, I) ==Bool false

  rule discoverChildren(FS, I) => discover(FS, I)

  syntax PathList ::= append(PathList, PathList) [function]
  rule append(.PathList, PS) => PS
  rule append(cons(P, PS), QS) => cons(P, append(PS, QS))
endmodule
