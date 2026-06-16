# FORMAL SPEC ENGLISH

Status: paraphrase of the K-style claims, constructed not machine-checked.

## C-SECTION-PREDICATE

The helper predicate is true at a position exactly when there is a following
line, the current line is non-empty, the following line is a non-empty repeated
underline character, and that underline is at least as long as the current line.

## C-SCAN-POSITION

The docinfo scan stops at the first line that is not docinfo or is a section
title. It advances only over lines that are docinfo and not section titles.

## C-ROLE-TITLE

For the role-heading shape from the issue, non-empty prolog is inserted before
the role title. The role title line remains immediately followed by its underline
after insertion.

## C-DOCINFO-PREFIX

For genuine leading docinfo, non-empty prolog is inserted after the docinfo
prefix and generated blank-line separator. The original suffix remains in order.

## C-NO-DOCINFO

For ordinary content with no leading docinfo, non-empty prolog is inserted at the
start and followed by a generated blank line before the original content.

## C-EMPTY-PROLOG

If prolog is falsey or empty, content is unchanged.

