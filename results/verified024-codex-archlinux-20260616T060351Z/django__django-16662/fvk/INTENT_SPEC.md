# Intent Spec

Status: intent-only, written before treating V1 behavior as correct.

The generated migration import block must put all plain `import ...` statements
before `from ... import ...` statements within the emitted block.

The writer should continue sorting by imported module/package within each import
style, matching the previous behavior where it does not conflict with the public
ordering rule.

The concrete issue witness must render as:

```python
import datetime
import time
from django.db import migrations, models
```

The repair should remain a small local tweak. Full isort behavior, blank-line
section grouping, and new formatter dependencies are outside the stated intent.
