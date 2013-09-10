======================
Lasso Domain Reference
======================

The Lasso domain (**ls:**) provides directives for each language element, as
well as corresponding roles for cross-referencing. See the `domain docs`_ for
more detail on syntax.


Directives
==========

Each directive populates the index.

.. rst:directive:: .. ls:type:: name
                   .. ls:trait:: name
                   .. ls:thread:: name

   Describes a type, trait, or thread. Member methods belonging to this element
   should be nested below or qualified with the ``element->member`` syntax.

   ``import``, ``imports``
      A comma-separated list of imported trait names.

   ``parent``, ``super``
      The ``parent`` element can appear in types and threads, which denotes
      another type that the current is derived from.

.. rst:directive:: .. ls:method:: name(signature)
                   .. ls:member:: name(signature)

   Describes an unbound or member method. The ``member`` directive is intended
   for methods belonging to a type, although both directives are treated
   identically.

   ``param``, ``parameter``
      Descriptions of parameters, with or without a type constraint. If an
      unnamed rest parameter is included, use ``...`` for the name.

   ``ptype``, ``paramtype``, ``type``
      Description of parameter type if more than one word is required.

   ``return``, ``returns``
      Description of the value returned.

   ``rtype``, ``returntype``
      Further description of the return value type.

.. rst:directive:: .. ls:provide:: name(signature)

   Describes a provide method for a trait or type. Prefixed with **provide** in
   output to distinguish from methods and members.

   Although a type's provide methods and import statements need to be inside a
   ``trait`` block in Lasso code, they can appear alongside member methods in
   reST markup.

.. rst:directive:: .. ls:require:: name(signature)

   Describes a require signature for a trait. Prefixed with **require** in
   output.

Every directive also supports the ``see`` or ``url`` option for adding links to
more info, and the ``author`` or ``authors`` option for adding an attribution.


Quick example
-------------

::

   .. ls:type:: rhino

      Description of the type

      :parent: :ls:type:`mammal`
      :import: :ls:trait:`trait_horned`
      :see: http://en.wikipedia.org/wiki/Rhinoceros

      .. ls:member:: numberOfHorns(species::string)::integer

         Description of the member method

         :param string species: Specifies which species
         :return: The number of horns


.. ls:type:: rhino

   Description of the type

   :parent: :ls:type:`mammal`
   :import: :ls:trait:`trait_horned`
   :see: http://en.wikipedia.org/wiki/Rhinoceros

   .. ls:member:: numberOfHorns(species::string)::integer

      Description of the member method

      :param string species: Specifies which species
      :return: The number of horns


Roles
=====

Cross-referencing is done with roles using the same syntax as other domains,
except that member tag syntax using the arrow operator ``->`` is used to
associate types or traits with member methods, such as
``:meth:`bytes->getrange```. All other syntax follows what's described in the
`domain docs`_.

Use the following roles to link to definitions of each element:

.. rst:role:: ls:meth

   Reference a type member method, trait provide method, trait require
   signature, or unbound method. Be sure to include the enclosing type or trait
   if outside its description block.

.. rst:role:: ls:type
              ls:trait
              ls:thread

   Reference a type, trait, or thread.


Quick example
-------------

::

   The :ls:type:`Pair <pair>` type always contains two elements which are accessed
   with the :ls:meth:`pair->first` and :ls:meth:`~pair->second` methods.


The :ls:type:`Pair <pair>` type always contains two elements which are accessed
with the :ls:meth:`pair->first` and :ls:meth:`~pair->second` methods.


More Info
=========

* Sphinx `domain docs`_
* `LassoGuide`_   
* `LassoSoft`_


.. _`domain docs`: http://sphinx-doc.org/latest/domains.html
.. _`LassoGuide`: http://www.lassoguide.com/
.. _`LassoSoft`: http://www.lassosoft.com/

