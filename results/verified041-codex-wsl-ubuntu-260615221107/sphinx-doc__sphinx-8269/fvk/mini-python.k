module MINI-PYTHON-SYNTAX
  imports INT-SYNTAX

  syntax StatusKind ::= "statusOK"
                      | "statusHttpError"
                      | "statusUnauthorized"
                      | "statusUnavailable"

  syntax AnchorState ::= "anchorFound"
                       | "anchorMissing"

  syntax RedirectState ::= "sameUrl"
                         | "redirectedUrl"

  syntax Result ::= "resultWorking"
                  | "resultWorkingUnauthorized"
                  | "resultIgnoredHttp"
                  | "resultBrokenHttp"
                  | "resultBrokenAnchor"
                  | "resultRedirected"

  syntax Stmt ::= "checkAnchorBranch" "(" StatusKind "," AnchorState "," RedirectState ")"

  syntax KResult ::= StatusKind | AnchorState | RedirectState | Result
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports INT

  configuration
    <k> $PGM:Stmt </k>
    <anchorChecks> 0 </anchorChecks>

  // HTTP status errors are classified before anchor parsing.
  rule <k> checkAnchorBranch(statusHttpError, A:AnchorState, R:RedirectState)
        => resultBrokenHttp ... </k>
       <anchorChecks> C:Int => C </anchorChecks>

  rule <k> checkAnchorBranch(statusUnauthorized, A:AnchorState, R:RedirectState)
        => resultWorkingUnauthorized ... </k>
       <anchorChecks> C:Int => C </anchorChecks>

  rule <k> checkAnchorBranch(statusUnavailable, A:AnchorState, R:RedirectState)
        => resultIgnoredHttp ... </k>
       <anchorChecks> C:Int => C </anchorChecks>

  // Successful responses reach the anchor parser.
  rule <k> checkAnchorBranch(statusOK, anchorMissing, R:RedirectState)
        => resultBrokenAnchor ... </k>
       <anchorChecks> C:Int => C +Int 1 </anchorChecks>

  rule <k> checkAnchorBranch(statusOK, anchorFound, sameUrl)
        => resultWorking ... </k>
       <anchorChecks> C:Int => C +Int 1 </anchorChecks>

  rule <k> checkAnchorBranch(statusOK, anchorFound, redirectedUrl)
        => resultRedirected ... </k>
       <anchorChecks> C:Int => C +Int 1 </anchorChecks>
endmodule
