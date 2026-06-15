# Formal Spec English

Status: paraphrase of `qdp-command-spec.k`; constructed, not machine-checked.

## LINE-TYPE-CASE-INSENSITIVE-READ-ERR

For any tokenized QDP error-command line whose first token is case-insensitively
equal to `read`, whose second token is case-insensitively equal to `serr` or
`terr`, and whose column list is non-empty, `lineType` returns `command`.

## LINE-TYPE-LOWERCASE-SERR-WITNESS

The concrete issue witness `read serr 1 2` is classified as `command`.

## LINE-TYPE-UPPERCASE-SERR-FRAME

The previously accepted uppercase command `READ SERR 1` remains classified as
`command`.

## LINE-TYPE-MIXEDCASE-TERR

A mixed-case `Read Terr 3` command is classified as `command`, showing that the
case-insensitive rule applies to both supported error command forms.

## ERR-SPEC-KEY-SERR-NORMALIZED

After a case-insensitive `SERR` command is classified, the error-spec key used
downstream is the canonical string `serr`.

## ERR-SPEC-KEY-TERR-NORMALIZED

After a case-insensitive `TERR` command is classified, the error-spec key used
downstream is the canonical string `terr`.
