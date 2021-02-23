=============================
@EricFromCanada’s Byte Bucket
=============================

AppleScript
-----------

`arrange windows`_
  Arranges windows for specified applications across two screens, because
  application windows don't preserve their positions on an external display if
  it's unplugged or sleeps (unless "Displays have separate Spaces" is enabled).
  `More info here
  <https://ericfromcanada.github.io/output/2017/arrange-windows-script.html>`_.

`close Safari Web Inspector`_
  Before Safari 6, the Web Inspector shortcut would only open it. Attach
  this AppleScript to another shortcut to make it closable.

`HTMLize Selected Text`_
  Runs selected text through Markdown.pl and SmartyPants.pl, and converts any
  MacRoman non-ASCII characters to HTML entities. (A relic from before UTF-8 was
  the standard online.)

`Journler2Blogger`_
  Uses the logic from HTMLize Selected Text to prepare a Journler entry for
  submission to Blogger. Includes the ability to convert rich text styles to
  HTML.

bash
----

`keyputter.sh`_
  Handy if you have a bunch of servers you need to install your SSH key onto and
  don't have ssh-copy-id.

`svn-user-htdigest.sh`_
  Use this to generate an htdigest file of users from an svnserve passwd file.
  Useful if you have a Trac installation using HTTPAuth and you need to grant
  your SVN users access.

`Time-Machine-NASifier.command`_
  Creates a Time Machine bundle for the current Mac with larger 128MB band files
  (up from 8MB) to improve performance when backing up to a non-HFS+ NAS.

BBEdit
------

`reStructuredText codeless language module`_
  Language module for BBEdit and TextWrangler which highlights elements
  in reStructuredText files and lists section titles in the function pop-up
  menu. Recognizes both standard reST directives and Sphinx additions. See its
  comments for my recommended editor settings.

`Lasso codeless language module`_
   Language module for BBEdit and TextWrangler which adds both Lasso 8- and
   9-style type and function names to the function menu, and highlights elements
   not supported by the current BBEdit language module such as ticked strings,
   tag literals, and variables.

`Liquid codeless language module`_
   Language module for BBEdit and TextWrangler which highlights only markup
   between Liquid delimiters, marking everything else as	comments. Supports
   keywords added in Liquid 5.0.0.

`Apache 2.4 Configuration codeless language module`_
   Update of John Gruber's `Apache Configuration Language Module
   <https://daringfireball.net/projects/apacheconfig/>`_ to include variables,
   Apache 2.4 keywords, and some bugfixes.

`Make codeless language module`_
   Update of BBEdit's / TextWrangler's built-in module to include more keywords
   from GNU make.

All these are also listed among the language modules at `BBEdit Extras
<http://www.bbeditextras.org/wiki/index.php?title=Codeless_Language_Modules>`_.

JavaScript
----------

`touch-menus-plus.js`_
  Makes navigation links with drop-down menus usable on iOS by only enabling
  the link if its submenu is visible. This is only required if JavaScript is
  used to hide and show submenus, since iOS accounts for CSS-based menus by
  preventing a ``:hover`` region's links from activating until any divs it'll
  reveal are displayed.

`Lasso lexer for highlight.js`_
  Contributed a lexer for the Lasso programming language for `highlight.js
  <https://highlightjs.org/>`_, a JS-based syntax highlighter. Included since
  version 7.4.

`Lasso lexer for code-prettify`_
  Also wrote a Lasso lexer for `code-prettify
  <https://github.com/google/code-prettify>`_, another JS-based syntax
  highlighter.

Lasso
-----

`completions-generator.lasso`_
  Script which generates a CodaCompletion.plist file for the `Coda 2 Lasso mode
  <https://github.com/LassoSoft/Lasso-HTML.mode>`_.

`sphinxifier.lasso`_
  Script for generating API documentation for Sphinx directly from Lasso code.

Python
------

`Lasso domain for Sphinx`_
   Domain plugin for the Sphinx documentation processor, allowing it to handle
   descriptions of Lasso syntax.

`Lasso lexer for Pygments`_
  Contributed a lexer for the Lasso programming language for the `Pygments
  <https://pygments.org/>`_ syntax highlighter. Included since version 1.6.

`restview`_
  Contributed CSS, syntax highlighting, and request handling improvements to
  restview, a tool for previewing reST documents in a web browser.

Ruby
----

`Homebrew`_
  Numerous contributions to Homebrew's commands, documentation, messaging, and
  `online package browser <https://formulae.brew.sh/>`_.

`Lasso lexer for Rouge`_
  Contributed a lexer for the Lasso programming language for the `Rouge
  <http://rouge.jneen.net>`_ syntax highlighter. Included since version 2.0.8.

More `about me`_ and `things I've written`_.


.. _arrange windows: https://github.com/EricFromCanada/byte-bucket/blob/master/applescript/arrange%20windows.applescript
.. _close Safari Web Inspector: https://github.com/EricFromCanada/byte-bucket/blob/master/applescript/close%20Safari%20Web%20Inspector.applescript
.. _HTMLize Selected Text: https://github.com/EricFromCanada/byte-bucket/blob/master/applescript/HTMLize%20Selected%20Text.applescript
.. _Journler2Blogger: https://github.com/EricFromCanada/byte-bucket/blob/master/applescript/Journler2Blogger.applescript
.. _keyputter.sh: https://github.com/EricFromCanada/byte-bucket/blob/master/bash/keyputter.sh
.. _svn-user-htdigest.sh: https://github.com/EricFromCanada/byte-bucket/blob/master/bash/svn-user-htdigest.sh
.. _Time-Machine-NASifier.command: https://github.com/EricFromCanada/byte-bucket/blob/master/bash/Time-Machine-NASifier.command
.. _reStructuredText codeless language module: https://github.com/EricFromCanada/byte-bucket/blob/master/bbedit/reStructuredText.plist
.. _Lasso codeless language module: https://github.com/EricFromCanada/byte-bucket/blob/master/bbedit/Lasso.plist
.. _Liquid codeless language module: https://github.com/EricFromCanada/byte-bucket/blob/master/bbedit/Liquid.plist
.. _Apache 2.4 Configuration codeless language module: https://github.com/EricFromCanada/byte-bucket/blob/master/bbedit/Apache%20Configuration.plist
.. _Make codeless language module: https://github.com/EricFromCanada/byte-bucket/blob/master/bbedit/Make.plist
.. _touch-menus-plus.js: https://github.com/EricFromCanada/byte-bucket/blob/master/javascript/touch-menus-plus.js
.. _Lasso lexer for highlight.js: https://github.com/highlightjs/highlight.js/blob/master/src/languages/lasso.js
.. _Lasso lexer for code-prettify: https://github.com/google/code-prettify/blob/master/src/lang-lasso.js
.. _completions-generator.lasso: https://github.com/EricFromCanada/byte-bucket/blob/master/lasso/completions-generator.lasso
.. _sphinxifier.lasso: https://github.com/EricFromCanada/byte-bucket/blob/master/lasso/sphinxifier.lasso
.. _Lasso domain for Sphinx: https://pypi.org/project/sphinxcontrib-lassodomain/
.. _Lasso lexer for Pygments: https://github.com/pygments/pygments/blob/master/pygments/lexers/javascript.py#L546
.. _restview: https://github.com/mgedmin/restview
.. _Homebrew: https://brew.sh/
.. _Lasso lexer for Rouge: https://github.com/rouge-ruby/rouge/blob/master/lib/rouge/lexers/lasso.rb
.. _about me: https://about.me/eric3knibbe
.. _things I've written: https://ericfromcanada.github.io
