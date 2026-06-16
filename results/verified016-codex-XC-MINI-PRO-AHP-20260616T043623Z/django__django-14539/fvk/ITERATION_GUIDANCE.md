# ITERATION GUIDANCE: django__django-14539

Status: V2 applied.

## Decision

Do not keep V1 unchanged. FVK finding F-002 showed that V1 still violated proof
obligations O-004 and O-005 when trailing punctuation was encoded as an HTML
entity. V2 replaces the count-only source slice with source-span trimming:

- move a whole trailing entity span when it decodes entirely to punctuation;
- otherwise move literal trailing punctuation source characters.

## Recommended follow-up tests

Do not edit tests in this benchmark. In a normal development environment, add or
confirm public tests for:

- `urlize('Search for google.com/?q=1&lt! and see.')`
- `urlize('Search for google.com/?q=1&lt;! and see.')`
- `urlize('Search for google.com/&#33; and see.')`
- `urlize('Search for google.com/&semi; and see.')`
- existing frame cases with `&amp;`, multiple literal punctuation marks, and no
  trailing punctuation.

## Commands to run later, not in this session

```sh
kompile fvk/mini-urlize.k --backend haskell
kast --backend haskell fvk/urlize-trim-spec.k
kprove fvk/urlize-trim-spec.k --definition fvk/mini-urlize-kompiled
```

After K machine-checking is available, run the relevant Django urlize tests and
the broader template/utils suites. No tests were run here because the task
forbids execution.

## Open risks

- The K model is a focused source-span model, not full Python.
- Behavior for extremely unusual HTML5 entity expansions that decode to mixed
  punctuation and non-punctuation is covered by the conservative literal
  fallback and should receive tests if Django wants to define that boundary
  precisely.
