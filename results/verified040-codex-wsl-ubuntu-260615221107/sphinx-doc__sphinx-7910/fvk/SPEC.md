# FVK Spec

Status: constructed, not machine-checked.

## Scope

The audited unit is `sphinx.ext.napoleon._skip_member()` and the new helper
`_get_class_from_qualname()`. The observable result is whether Napoleon returns
`False` to force autodoc to include a member, or `None` to leave autodoc's
default skip decision unchanged.

The formal model abstracts real Python objects into the metadata used by this
code path:

- `what`: `class`, `exception`, `module`, or another autodoc object type.
- `name`: `init`, `private`, `special`, `weakref`, or `public`.
- `has_doc`: whether `obj.__doc__` is truthy.
- `resolve`: whether module+qualname resolution finds an owner class, and
  whether `unwrap(cls)` finds a wrapped original owner.
- `global_owner`: whether the old top-level `obj.__globals__[cls_path]`
  fallback finds an owner.
- `config`: the three Napoleon include-with-doc settings.

## Public Intent Ledger

The detailed ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`; the intent-only
requirements are in `fvk/INTENT_SPEC.md`.

Critical obligations:

- I1-I3: decorated `__init__` methods using `functools.wraps()` must be
  recognized as class members without relying on wrapper globals.
- I4: nested-class module+qualname lookup must remain supported.
- I5-I6: the existing include settings, module-member behavior, and
  `__weakref__` exclusion remain gates.
- I7: class decoration should be handled when a wrapper exposes the original
  class through `__wrapped__`.
- I8: `_skip_member`'s public callback signature and return protocol must not
  change.

## Intended Contract

For `name != "__weakref__"`, truthy `obj.__doc__`, and `what` in
`{"class", "exception", "module"}`:

1. If `what == "module"`, ownership is accepted and the relevant include
   setting decides whether to return `False`.
2. If `what` is `class` or `exception`, ownership is accepted when:
   - `obj.__module__` plus the class portion of `obj.__qualname__` resolves to
     a class whose `__dict__` contains `name`;
   - or `unwrap(cls)` resolves to such a class, for decorated-class wrappers;
   - or module+qualname resolution fails for a top-level class path and the
     previous `obj.__globals__[cls_path]` lookup finds an owner.
3. If ownership is accepted and the relevant include-with-doc setting is true,
   return `False`; otherwise return `None`.

## Formal Core

The K semantics fragment is `fvk/mini-napoleon.k`.

The claim file is `fvk/napoleon-skip-member-spec.k`.

The formal English round-trip is:

- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

The claims cover:

- C1 decorated method init;
- C2 decorated class init through `__wrapped__`;
- C3 nested/private owner resolution;
- C4 top-level fallback compatibility;
- C5 no-owner default behavior;
- C6 config gate behavior;
- C7 module private behavior;
- C8 weakref exclusion.

## Domain And Limits

This is a partial-correctness proof over the ownership and include-decision
slice. It does not model the full Python import system, descriptor protocol, or
autodoc member enumeration. Those are retained as integration-test obligations
in `fvk/ITERATION_GUIDANCE.md`.
