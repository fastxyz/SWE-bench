module MINI-PYTHON-HTML-FORMAT-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX
  imports MAP-SYNTAX

  syntax Format ::= "none" | "fmt" "(" String ")"
  syntax Col ::= "col" "(" String "," Format "," Int ")"
  syntax Cols ::= ".Cols" | Col Cols [right]
  syntax Action ::= "htmlWrite" "(" Cols "," Map "," Bool ")"
                  | "setColFormats" "(" Cols "," Map ")"
                  | "splitWithSourceFormat" "(" Col "," Int ")"
  syntax KResult ::= Cols
endmodule

module MINI-PYTHON-HTML-FORMAT
  imports MINI-PYTHON-HTML-FORMAT-SYNTAX
  imports BOOL
  imports INT
  imports STRING
  imports MAP

  configuration
    <k> $PGM:Action </k>
    <cols> .Cols </cols>

  // Abstract action corresponding to V1's:
  // self.data.cols = cols; self.data._set_col_formats(); render iterators.
  rule <k> htmlWrite(CS, FMTS, MULTI) => setColFormats(CS, FMTS) ... </k>

  rule <k> setColFormats(.Cols, FMTS) => .Cols ... </k>
       <cols> _ => .Cols </cols>

  rule <k> setColFormats(col(NAME, OLD, SHAPE) REST, FMTS)
        => setColFormats(REST, FMTS) ... </k>
       <cols> CS => col(NAME, fmt(FMTS[NAME]), SHAPE) CS </cols>
    requires NAME in_keys(FMTS)

  rule <k> setColFormats(col(NAME, OLD, SHAPE) REST, FMTS)
        => setColFormats(REST, FMTS) ... </k>
       <cols> CS => col(NAME, OLD, SHAPE) CS </cols>
    requires notBool (NAME in_keys(FMTS))

  // Abstract action corresponding to V1's:
  // new_col.info.format = col.info.format before new_col.info.iter_str_vals().
  rule <k> splitWithSourceFormat(col(NAME, FMT, SHAPE), I) => col(NAME, FMT, 1) ... </k>
    requires 0 <=Int I andBool I <Int SHAPE
endmodule
