# Intent Spec

Status: intent-only, written from public evidence before accepting candidate
behavior as expected behavior.

1. `Card.fromstring(str(Card(keyword, value, comment))).value` should preserve
   the logical string value for FITS string cards, including values represented
   through `CONTINUE` cards.
2. Logical doubled single quotes in Python string values, such as `''`, must not
   collapse to a single quote after serialization and parsing.
3. A doubled quote followed by a space and more text, such as `'' aaa`, must
   preserve the doubled quote, the space, and the trailing text.
4. The `CONTINUE` ampersand is a physical-card continuation marker and is not
   part of the logical string value.
5. `CONTINUE` cards are transparent to callers: a set of physical card images
   represents one logical card.
6. Public APIs, header grouping behavior, and existing long-comment handling
   should remain unchanged.

Observed pre-fix issue outputs that collapse quotes or drop trailing text are
SUSPECT legacy behavior and are not expected results.
