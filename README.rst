AppleScript
-----------

`close Safari Web Inspector script`_
  Before Safari 6, the Web Inspector shortcut would only open it. Attach
  this AppleScript to another shortcut to make it closable.

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

`Apache 2.4 Configuration codeless language module`_
   Update of John Gruber's `Apache Configuration Language Module`_ to include
   variables, Apache 2.4 keywords, and some bugfixes.

`Make codeless language module`_
   Update of BBEdit's / TextWrangler's built-in module to include more keywords
   from GNU make.

JavaScript
----------

`touch-menus-plus.js`_
  Makes navigation links with drop-down menus usable on iOS by only enabling
  the link if its submenu is visible. This is only required if JavaScript is
  used to hide and show submenus, since iOS accounts for CSS-based menus by
  preventing a ``:hover`` region's links from activating until any divs it'll
  reveal are displayed.

`Lasso lexer for highlight.js`_
  Contributed a lexer for the Lasso programming language for highlight.js_, a
  JS-based syntax highlighter. Included since version 7.4.

`Lasso lexer for code-prettify`_
  Also wrote a Lasso lexer for code-prettify_, another JS-based syntax
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
  Contributed a lexer for the Lasso programming language for the Pygments_
  syntax highlighter. Included since Pygments 1.6.

`restview`_
  Contributed CSS, syntax highlighting, and request handling improvements to
  restview, a tool for previewing reST documents in a web browser.

More `about me`_.


.. _Browse all files: https://bitbucket.org/EricFromCanada/ericfromcanada.bitbucket.org/src/
.. _close Safari Web Inspector script: https://bitbucket.org/EricFromCanada/ericfromcanada.bitbucket.org/raw/default/applescript/close%20Safari%20Web%20Inspector.applescript
.. _keyputter.sh: https://bitbucket.org/EricFromCanada/ericfromcanada.bitbucket.org/raw/default/bash/keyputter.sh
.. _svn-user-htdigest.sh: https://bitbucket.org/EricFromCanada/ericfromcanada.bitbucket.org/raw/default/bash/svn-user-htdigest.sh
.. _Time-Machine-NASifier.command: https://bitbucket.org/EricFromCanada/ericfromcanada.bitbucket.org/raw/default/bash/Time-Machine-NASifier.command
.. _reStructuredText codeless language module: https://bitbucket.org/EricFromCanada/ericfromcanada.bitbucket.org/raw/default/bbedit/reStructuredText.plist
.. _Apache 2.4 Configuration codeless language module: https://bitbucket.org/EricFromCanada/ericfromcanada.bitbucket.org/raw/default/bbedit/Apache%20Configuration.plist
.. _Apache Configuration Language Module: http://daringfireball.net/projects/apacheconfig/
.. _Lasso codeless language module: https://bitbucket.org/EricFromCanada/ericfromcanada.bitbucket.org/raw/default/bbedit/Lasso.plist
.. _Make codeless language module: https://bitbucket.org/EricFromCanada/ericfromcanada.bitbucket.org/raw/default/bbedit/Make.plist
.. _touch-menus-plus.js: https://bitbucket.org/EricFromCanada/ericfromcanada.bitbucket.org/raw/default/javascript/touch-menus-plus.js
.. _Lasso lexer for highlight.js: https://github.com/isagalaev/highlight.js/blob/master/src/languages/lasso.js
.. _highlight.js: https://highlightjs.org/
.. _Lasso lexer for code-prettify: https://github.com/google/code-prettify/blob/master/src/lang-lasso.js
.. _code-prettify: https://github.com/google/code-prettify
.. _completions-generator.lasso: https://bitbucket.org/EricFromCanada/ericfromcanada.bitbucket.org/raw/default/lasso/completions-generator.lasso
.. _sphinxifier.lasso: https://bitbucket.org/EricFromCanada/ericfromcanada.bitbucket.org/raw/default/lasso/sphinxifier.lasso
.. _Lasso domain for Sphinx: https://pypi.python.org/pypi/sphinxcontrib-lassodomain/
.. _Lasso lexer for Pygments: https://bitbucket.org/EricFromCanada/pygments-main
.. _Pygments: http://pygments.org/
.. _restview: https://github.com/mgedmin/restview
.. _about me: https://about.me/eric3knibbe
