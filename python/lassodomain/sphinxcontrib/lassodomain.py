# -*- coding: utf-8 -*-
"""
    sphinx.domains.lasso
    ~~~~~~~~~~~~~~~~~~~~

    The Lasso domain, based off of the standard Python and JavaScript domains.

    :copyright: Copyright 2013 by Eric Knibbe
    :license: BSD, see LICENSE for details.
"""

from sphinx import addnodes
from sphinx.directives import ObjectDescription
from sphinx.domains import Domain, ObjType
from sphinx.domains.python import _pseudo_parse_arglist
from sphinx.locale import l_, _
from sphinx.roles import XRefRole
from sphinx.util.compat import Directive
from sphinx.util.docfields import Field, GroupedField, TypedField
from sphinx.util.nodes import make_refnode


class LSObject(ObjectDescription):
    """
    Description of a Lasso object.
    """
    doc_field_types = [
        # :param name: description
        # :ptype name: typename (optional)
        # - or -
        # :param typename name: description
        TypedField('parameter', label=l_('Parameters'), can_collapse=True,
                   names=('param', 'parameter'), typerolename='obj',
                   typenames=('ptype', 'paramtype', 'type')),
        # :return: description (if no return type specified)
        Field('return', label=l_('Returns'), has_arg=False,
              names=('return', 'returns')),
        # :returnas typename: description (if return type is specified)
        Field('returnas', label=l_('Returns as'), has_arg=True,
              names=('returnas','returnsas')),
        # :see: resource
        Field('seealso', label=l_('See also'), has_arg=False,
              names=('see', 'url')),
        # :parent: typename
        Field('parent', label=l_('Parent'), has_arg=False,
              names=('parent')),
        # :import: trait_1, trait_2
        Field('import', label=l_('Imports'), has_arg=False,
              names=('import', 'imports')),
    ]

    def get_signature_prefix(self, sig):
        """May return a prefix to put before the object name in the
        signature.
        """
        return ''

    def needs_arglist(self):
        """May return true if an empty argument list is to be generated even if
        the document contains none.
        """
        return False

    def handle_signature(self, sig, signode):
        sig = sig.strip()
        if '(' in sig and sig[-1:] == ')':
            prefix, arglist = sig.split('(', 1)
            prefix = prefix.strip()
            arglist = arglist[:-1].strip()
        else:
            prefix = sig
            arglist = None
        if '->' in prefix:
            nameprefix, name = prefix.rsplit('->', 1)
        else:
            nameprefix = None
            name = prefix

        objectname = self.env.temp_data.get('ls:object')
        if nameprefix:
            #if objectname:
                # if an object has been set on the page and the item name
                # includes a prefix, ignore the page object
                #nameprefix = objectname + '->' + nameprefix
            fullname = nameprefix + '->' + name
        elif objectname:
            fullname = objectname + '->' + name
        else:
            # no current object set and no prefix, denoting an unbound method
            objectname = ''
            fullname = name

        signode['object'] = objectname
        signode['fullname'] = fullname

        sig_prefix = self.get_signature_prefix(sig)
        if sig_prefix:
            signode += addnodes.desc_annotation(sig_prefix, sig_prefix)

        if nameprefix:
            signode += addnodes.desc_addname(nameprefix + '->',
                                             nameprefix + '->')
        signode += addnodes.desc_name(name, name)
        if self.needs_arglist():
            if not arglist:
                signode += addnodes.desc_parameterlist()    # add empty signature
            else:
                _pseudo_parse_arglist(signode, arglist)     # from the python domain
        return fullname, nameprefix

    def add_target_and_index(self, name_obj, sig, signode):
        objectname = self.options.get(
            'object', self.env.temp_data.get('ls:object'))
        fullname = name_obj[0]
        if fullname not in self.state.document.ids:
            signode['names'].append(fullname)
            signode['ids'].append(fullname)
            signode['first'] = not self.names
            self.state.document.note_explicit_target(signode)
            objects = self.env.domaindata['ls']['objects']
            if fullname in objects:
                self.state_machine.reporter.warning(
                    'duplicate object description of %s, ' % fullname +
                    'other instance in ' +
                    self.env.doc2path(objects[fullname][0]),
                    line=self.lineno)
            objects[fullname] = self.env.docname, self.objtype

        indextext = self.get_index_text(objectname, name_obj)
        if indextext:
            self.indexnode['entries'].append(('single', indextext,
                                              fullname, ''))

    def get_index_text(self, objectname, name_obj):
        name, obj = name_obj
        if self.objtype == 'method':
            if not obj:
                return _('%s') % name
            return _('%s->%s') % (obj, name)
        elif self.objtype == 'provide':
            return _('%s->%s') % (obj, name)
        return _('%s (%s)') % (name, self.objtype)


class LSDefinition(LSObject):
    """Description of an object definition (types, traits, threads)."""
    def get_signature_prefix(self, sig):
        return self.objtype + ' '


class LSCallable(LSObject):
    """Description of an object with a signature."""
    def needs_arglist(self):
        return True


class LSTraitTag(LSCallable):
    """Description of an object within a trait."""
    def get_signature_prefix(self, sig):
        return self.objtype + ' '


class LSXRefRole(XRefRole):
    """
    Provides cross reference links for Lasso objects.
    """
    def process_link(self, env, refnode, has_explicit_title, title, target):
        refnode['ls:object'] = env.temp_data.get('ls:object')
        if not has_explicit_title:
            title = title.lstrip('->')
            target = target.lstrip('~')
            if title[0:1] == '~':
                title = title[1:]
                arrow = title.rfind('->')
                if arrow != -1:
                    title = title[arrow+2:]
        if target[0:2] == '->':
            target = target[2:]
            refnode['refspecific'] = True
        return title, target


class LassoDomain(Domain):
    """
    Lasso language domain.
    """
    name = 'ls'
    label = 'Lasso'
    object_types = {
        'method':  ObjType(l_('method'),  'meth', 'obj'),
        'trait':   ObjType(l_('trait'),   'trait', 'obj'),
        'type':    ObjType(l_('type'),    'type', 'obj'),
        'thread':  ObjType(l_('thread'),  'thread', 'obj'),
        'provide': ObjType(l_('provide'), 'meth', 'obj'),
        'require': ObjType(l_('require'), 'meth', 'obj'),
    }
    directives = {
        'method':  LSCallable,
        'type':    LSDefinition,
        'trait':   LSDefinition,
        'thread':  LSDefinition,
        'provide': LSTraitTag,
        'require': LSTraitTag,  # name and signature only
    }
    roles = {
        'meth':   LSXRefRole(fix_parens=True),
        'trait':  LSXRefRole(),
        'type':   LSXRefRole(),
        'thread': LSXRefRole(),
    }
    initial_data = {
        'objects': {}, # fullname -> docname, objtype
    }

    def clear_doc(self, docname):
        for fullname, (fn, _) in self.data['objects'].items():
            if fn == docname:
                del self.data['objects'][fullname]

    def find_obj(self, env, obj, name, typ, searchorder=0):
        if name[-2:] == '()':
            name = name[:-2]
        objects = self.data['objects']
        newname = None
        if searchorder == 1:
            if obj and obj + '->' + name in objects:
                newname = obj + '->' + name
            else:
                newname = name
        else:
            if name in objects:
                newname = name
            elif obj and obj + '->' + name in objects:
                newname = obj + '->' + name
        return newname, objects.get(newname)

    def get_objects(self):
        for refname, (docname, type) in self.data['objects'].iteritems():
            yield (refname, refname, type, docname, refname, 1)

    def resolve_xref(self, env, fromdocname, builder,
                     typ, target, node, contnode):
        objectname = node.get('ls:object')
        searchorder = node.hasattr('refspecific') and 1 or 0
        name, obj = self.find_obj(env, objectname, target, typ, searchorder)
        if not obj:
            return None
        return make_refnode(builder, fromdocname, obj[0], name, contnode, name)


def setup(app):
    app.add_domain(LassoDomain)
