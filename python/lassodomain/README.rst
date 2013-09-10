============
Lasso Domain
============

:author: Eric Knibbe <eric at lassosoft dotcom>


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


Installation
============

After installing ``lassodomain.py`` in ``site-packages/sphinxcontrib``, add the
``sphinxcontrib.lassodomain`` extension to the ``extensions`` list in your
Sphinx configuration file (``conf.py``)::

   extensions = ['sphinxcontrib.lassodomain']

Also, if your project is primarily Lasso, you'll want to define the primary
domain as well::

   primary_domain = 'ls'


Directives example
==================

The source below will generate the following output::

   .. ls:method:: tag_exists(p0::string)

      Indicates whether a tag currently exists.

      :param string find: the tag name to search for

   .. ls:member:: array->exchange(left::integer, right::integer)

      Exchanges the two elements within the array.

   .. ls:type:: string

      Text in Lasso is stored and manipulated using the :ls:type:`String
      <string>` data type or the ``string_...`` methods.

      :see:    http://lassoguide.com/operations/strings.html
      :parent: :ls:type:`null`

      .. ls:member:: find(find, offset::integer[, -case::boolean=false])::integer

         Finds the position in the string where the given pattern
         matches. Analogous to the :ls:meth:`String_FindPosition` method.

         Takes a parameter that specifies a pattern to search the string
         object for and returns the position in the string object where
         that pattern first begins or zero if the pattern cannot be
         found.

         :param find: a pattern to search the string object for
         :param integer offset: where to start the search
         :param -case: whether to consider character case when searching
         :ptype -case: boolean, default false
         :return:
            Position in the string object where the pattern first begins,
            or zero if the pattern cannot be found.
         :rtype: integer

   .. ls:trait:: trait_foreach

      Provides iteration over a series of values.

      :import: :ls:trait:`trait_decompose_assignment`

      .. ls:require:: forEach()

      .. ls:provide:: asGenerator()::trait_generator

         Allows the type to act as a generator.

         :rtype: `trait_generator`


.. ls:method:: tag_exists(p0::string)

   Indicates whether a tag currently exists.

   :param string find: the tag name to search for

.. ls:member:: array->exchange(left::integer, right::integer)

   Exchanges the two elements within the array.

.. ls:type:: string

   Text in Lasso is stored and manipulated using the :ls:type:`String
   <string>` data type or the ``string_...`` methods.

   :see:    http://lassoguide.com/operations/strings.html
   :parent: :ls:type:`null`

   .. ls:member:: find(find, offset::integer[, -case::boolean=false])::integer

      Finds the position in the string where the given pattern
      matches. Analogous to the :ls:meth:`String_FindPosition` method.

      Takes a parameter that specifies a pattern to search the string
      object for and returns the position in the string object where
      that pattern first begins or zero if the pattern cannot be
      found.

      :param find: a pattern to search the string object for
      :param integer offset: where to start the search
      :param -case: whether to consider character case when searching
      :ptype -case: boolean, default false
      :return:
         Position in the string object where the pattern first begins,
         or zero if the pattern cannot be found.
      :rtype: integer

.. ls:trait:: trait_foreach

   Provides iteration over a series of values.

   :import: :ls:trait:`trait_decompose_assignment`

   .. ls:require:: forEach()

   .. ls:provide:: asGenerator()::trait_generator

      Allows the type to act as a generator.

      :rtype: `trait_generator`


Roles example
=============

From elsewhere in the document you can use the following syntax to link to
definitions of each element. Note how types and member methods are linked with
the ``->`` operator::

   Use :ls:meth:`array->exchange` to swap the position of two array elements.


Use :ls:meth:`array->exchange` to swap the position of two array elements.

