module MINI-ERA001-SCRIPT-SCAN-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Content ::= invalidContent()
                   | content(String)

  // line(StartOffset, FullEndOffset, ParsedContent)
  syntax Line ::= line(Int, Int, Content)
  syntax Lines ::= ".Lines"
                 | Line ";;" Lines [right]

  syntax MaybeInt ::= noneInt()
                    | someInt(Int)

  syntax MaybeInt ::= scan(Lines) [function]
                    | scanFrom(Lines, MaybeInt) [function]
  syntax Lines ::= skipBefore(Int, Lines) [function]
endmodule

module MINI-ERA001-SCRIPT-SCAN
  imports MINI-ERA001-SCRIPT-SCAN-SYNTAX
  imports INT
  imports BOOL
  imports STRING

  configuration <k> $PGM:K </k>

  rule scan(LS:Lines) => scanFrom(LS, noneInt())

  // End of file or first invalid embedded-content line: return the last delimiter seen.
  rule scanFrom(.Lines, LAST:MaybeInt) => LAST
  rule scanFrom(line(START:Int, END:Int, invalidContent()) ;; LS:Lines, LAST:MaybeInt) => LAST

  // V1 behavior: every valid delimiter overwrites the candidate close.
  rule scanFrom(line(START:Int, END:Int, content("///")) ;; LS:Lines, LAST:MaybeInt)
    => scanFrom(LS, someInt(END))

  // Non-delimiter embedded content preserves the candidate close.
  rule scanFrom(line(START:Int, END:Int, content(C:String)) ;; LS:Lines, LAST:MaybeInt)
    => scanFrom(LS, LAST)
    requires C =/=String "///"

  // Comment iterator advancement mirrors `while comment.start() < end_offset`.
  rule skipBefore(END:Int, .Lines) => .Lines
  rule skipBefore(END:Int, line(START:Int, FULL_END:Int, C:Content) ;; LS:Lines)
    => skipBefore(END, LS)
    requires START <Int END
  rule skipBefore(END:Int, line(START:Int, FULL_END:Int, C:Content) ;; LS:Lines)
    => line(START, FULL_END, C) ;; LS
    requires START >=Int END
endmodule
