Root cause
==========

`sphinx.ext.viewcode` already skipped collecting new module information in
`doctree_read()` when the active builder was EPUB and `viewcode_enable_epub`
was false.  However, EPUB builders inherit the standalone HTML builder and
therefore still emit the `html-collect-pages` event during the finish phase.
When `make html epub` is used, the EPUB build can load an environment that was
previously populated by the HTML build with `_viewcode_modules`.  Because
`collect_pages()` did not repeat the EPUB/config check, it generated `_modules`
pages from that stale-but-valid HTML viewcode data.

Changed files
=============

`repo/sphinx/ext/viewcode.py`

Added the same EPUB opt-in guard to `collect_pages()` that already exists in
`doctree_read()`.  This prevents viewcode from emitting generated module pages
for EPUB builds unless `viewcode_enable_epub` is explicitly true, including
when the build environment was reused after an HTML build.

Assumptions and alternatives
============================

I assumed the intended behavior is that `viewcode_enable_epub = False` disables
all viewcode-generated EPUB module pages, not only fresh source collection.
This matches the configuration documentation and the issue's expectation that
module pages should not be created for EPUB by default.

I considered clearing `_viewcode_modules` during EPUB builds instead.  I
rejected that because the data can legitimately belong to other HTML-related
builders sharing the environment, and clearing it would be broader than needed.

I also considered changing the event registration so `collect_pages()` is not
connected for EPUB.  I rejected that because the callback needs to remain
available for EPUB builds when `viewcode_enable_epub` is true.
