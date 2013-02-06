.. title:: Eric's bits of code

==============================
 ericfromcanada.bitbucket.org
==============================

Various pieces of code I've written, in case someone else finds them useful.

`Browse all files <https://bitbucket.org/EricFromCanada/ericfromcanada.bitbucket.org/src/>`_

AppleScript
-----------

`close Safari Web Inspector script <https://bitbucket.org/EricFromCanada/ericfromcanada.bitbucket.org/raw/default/applescript/close%20Safari%20Web%20Inspector.applescript>`_
  Before Safari 6, the Web Inspector shortcut would only open it. Attach 
  this AppleScript to another shortcut to make it closeable.
  
bash
----

`keyputter.sh <https://bitbucket.org/EricFromCanada/ericfromcanada.bitbucket.org/raw/default/bash/keyputter.sh>`_
  Handy if you have a bunch of servers you need to install your SSH key onto.

`svn-user-htdigest.sh <https://bitbucket.org/EricFromCanada/ericfromcanada.bitbucket.org/raw/default/bash/svn-user-htdigest.sh>`_
  Use this to generate an htdigest file of users from an svnserve passwd file.
  Useful if you have a Trac installation using HTTPAuth and you need to grant
  your SVN users access.
  
BBEdit
------

`reST codeless language module <https://bitbucket.org/EricFromCanada/ericfromcanada.bitbucket.org/raw/default/bbedit/reStructuredText.plist>`_
  Language module for BBEdit and TextWrangler which highlights elements 
  in reStructuredText files and lists section titles in the function pop-up
  menu. Recognizes both standard reST directives and Sphinx additions.
  
  I recommend also setting these options for editing reStructuredText: enabling
  auto-indent and auto-expand tabs, setting tab width to 3 spaces, disabling 
  soft wrap text, and setting the page guide to 80 characters. 

JavaScript
----------
  
`touch-menus-plus.js <https://bitbucket.org/EricFromCanada/ericfromcanada.bitbucket.org/raw/default/javascript/touch-menus-plus.js>`_
  Makes navigation links with drop-down menus usable on iOS by only enabling
  the link if its submenu is visible. This is only required if JavaScript is
  used to hide and show submenus, since iOS accounts for CSS-based menus by
  preventing a ``:hover`` region's links from activating until any divs it'll
  reveal are displayed.
  
  `See it in action <http://www.treefrog.ca/>`_

Python
------

`restview (improved) <https://bitbucket.org/EricFromCanada/ericfromcanada.bitbucket.org/raw/default/python/restview/>`_
  My branch of the excellent restview_, a tool for previewing reST documents
  in a web browser, with some improvements I made to the CSS, syntax highlighting,
  and request handling components.

`Lasso lexer for Pygments <https://bitbucket.org/EricFromCanada/pygments-main>`_
  Contributed a lexer for the Lasso programming language for the Pygments_
  syntax highlighter. Expect to see it included in Pygments 1.6.

Find me on Twitter_.

.. _restview: http://mg.pov.lt/restview/
.. _Pygments: http://pygments.org/
.. _Twitter: https://twitter.com/EricFromCanada
