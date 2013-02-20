============
Lasso Domain
============

:author: Eric Knibbe <eric@lassosoft.com>


About
=====

This extension adds a Lasso domain to Sphinx. It is currently a somewhat
functional work in progress.


Usage
=====

After installing lassodomain.py in site-packages/sphinxcontrib, add the
extension to your list of extensions in conf.py::

  extensions = ['sphinx.ext.autodoc', 'sphinxcontrib.lassodomain']

Also, if your project is primarily Lasso, you'll want to define the primary
domain as well::

  primary_domain = 'ls'


Directives and Roles
====================

This domain provides method, type, trait, thread, provide, and require
directives, as well as meth, trait, type, and thread roles for 
cross-referencing. To link to a member method, use member tag syntax, such as 
``:meth:`Bytes->getrange```.

.. add more examples here
