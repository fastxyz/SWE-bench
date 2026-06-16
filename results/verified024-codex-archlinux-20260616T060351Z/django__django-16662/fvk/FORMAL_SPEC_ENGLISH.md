# Formal Spec In English

Status: paraphrase of the constructed K claims.

`ORDERED-BY-STYLE-MODULE`: for every finite list of generated migration import
lines, running the import sorter returns the same lines in an order where the
tuple `(style_rank, module_token)` is nondecreasing. `style_rank` is `0` for
plain `import ...` lines and `1` for `from ... import ...` lines.

`ISSUE-WITNESS`: for the list containing `import datetime`,
`from django.db import migrations, models`, and `import time`, the import sorter
returns `import datetime`, then `import time`, then
`from django.db import migrations, models`.

Frame condition: the sort operation reorders import lines only. It does not
change import collection, the `django.db` migrations/models merge, dependency
rendering, operation rendering, or manual-porting comments.

Side condition: input lines are generated import lines with a first token of
`import` or `from` and a second token containing the imported module/package.
