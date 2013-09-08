============
Lasso Domain
============

:author: Eric Knibbe <eric@lassosoft.com>


About
=====

This extension adds support for the Lasso language to Sphinx.

The following objects are supported:

* Unbound method
* Trait

  * Require
  * Provide

* Type/Thread

  * Member method
  * Provide

Methods are associated with their type or trait using the arrow operator::

	Type->member_method


Usage
=====

After installing :file:`lassodomain.py` in `site-packages/sphinxcontrib`, add the
:mod:`sphinxcontrib.lassodomain` extension to the :data:`extensions` list in
your Sphinx configuration file (:file:`conf.py`)::

  extensions = ['sphinxcontrib.lassodomain']

Also, if your project is primarily Lasso, you'll want to define the primary
domain as well::

  primary_domain = 'ls'

