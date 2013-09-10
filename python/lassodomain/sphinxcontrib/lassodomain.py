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
    """Description of a Lasso object.
    """
    doc_field_types = [
        # :param name: description
        # :ptype name: typename (optional)
        # - or -
        # :param typename name: description
        TypedField('parameter', label=l_('Parameters'), can_collapse=True,
                   names=('param', 'parameter'), typerolename='obj',
                   typenames=('ptype', 'paramtype', 'type')),
        # :return: description
        Field('returnvalue', label=l_('Returns'), has_arg=False,
              names=('return', 'returns')),
        # :rtype: typename
        Field('returntype', label=l_('Return type'), has_arg=False,
              names=('rtype', 'returntype')),
        # :author: name
        Field('author', label=l_('Author'), has_arg=False,
              names=('author', 'authors')),
        # :see: resource
        Field('seealso', label=l_('See also'), has_arg=False,
              names=('see', 'url')),
        # :parent: typename
        Field('parent', label=l_('Parent type'), has_arg=False,
              names=('parent', 'super')),
        # :import: trait_name
        Field('import', label=l_('Imports'), has_arg=False,
              names=('import', 'imports')),
    ]

    def needs_arglist(self):
        """May return true if an empty argument list is to be generated even if
        the document contains none.
        """
        return False

    def get_signature_prefix(self, sig):
        """May return a prefix to put before the object name in the signature.
        """
        return ''

    def get_index_text(self, objectname, name_obj):
        """Return the text for the index entry of the object.
        """
        raise NotImplementedError('must be implemented in subclasses')

    def handle_signature(self, sig, signode):
        """Transform a Lasso signature into RST nodes.
        """
        sig = sig.strip()
        if '(' in sig:
            if ')::' in sig:
                sig, returntype = sig.rsplit('::', 1)
            else:
                returntype = None
            prefix, arglist = sig.split('(', 1)
            prefix = prefix.strip()
            arglist = arglist[:-1].strip()
        else:
            if '::' in sig:
                sig, returntype = sig.rsplit('::', 1)
            else:
                returntype = None
            prefix = sig
            arglist = None
        if '->' in prefix:
            name_prefix, name = prefix.rsplit('->', 1)
        else:
            name_prefix = None
            name = prefix

        objectname = self.env.temp_data.get('ls:object')
        if name_prefix:
            fullname = name_prefix + '->' + name
        elif objectname:
            fullname = objectname + '->' + name
        else:
            objectname = ''
            fullname = name

        signode['object'] = objectname
        signode['fullname'] = fullname

        sig_prefix = self.get_signature_prefix(sig)
        if sig_prefix:
            signode += addnodes.desc_annotation(sig_prefix, sig_prefix)
        if name_prefix:
            name_prefix += '->'
            signode += addnodes.desc_addname(name_prefix, name_prefix)
        signode += addnodes.desc_name(name, name)
        if self.needs_arglist():
            if not arglist:
                signode += addnodes.desc_parameterlist()
            else:
                _pseudo_parse_arglist(signode, arglist)
            if returntype:
                signode += addnodes.desc_returns(returntype, returntype)
        return fullname, name_prefix

    def add_target_and_index(self, name_obj, sig, signode):
        fullname = name_obj[0]
        objectname = self.env.temp_data.get('ls:object')
        if fullname not in self.state.document.ids:
            signode['names'].append(fullname)
            signode['ids'].append(fullname)
            signode['first'] = (not self.names)
            self.state.document.note_explicit_target(signode)
            objects = self.env.domaindata['ls']['objects']
            if fullname in objects:
                self.state_machine.reporter.warning(
                    'duplicate object description of %s, ' % fullname +
                    'other instance in ' +
                    self.env.doc2path(objects[fullname][0]) +
                    ', use :noindex: for one of them',
                    line=self.lineno)
            objects[fullname] = self.env.docname, self.objtype

        indextext = self.get_index_text(objectname, name_obj)
        if indextext:
            self.indexnode['entries'].append(('single', indextext,
                                              fullname, ''))

    def before_content(self):
        # needed for automatic qualification of members (reset in subclasses)
        self.objname_set = False

    def after_content(self):
        if self.objname_set:
            self.env.temp_data['ls:object'] = None


class LSDefinition(LSObject):
    """Description of an object definition (type, trait, thread).
    """
    def get_signature_prefix(self, sig):
        return self.objtype + ' '

    def get_index_text(self, objectname, name_obj):
        return _('%s (%s)') % (name_obj[0], self.objtype)

    def before_content(self):
        LSObject.before_content(self)
        if self.names:
            self.env.temp_data['ls:object'] = self.names[0][0]
            self.objname_set = True


class LSTag(LSObject):
    """Description of an object with a signature (method, member).
    """
    def needs_arglist(self):
        return True

    def get_index_text(self, objectname, name_obj):
        name = name_obj[0].split('->')[-1]
        if not (objectname or name_obj[1]):
            return _('%s() (method)') % name
        else:
            objectname = name_obj[0].split('->')[0]
        return _('%s() (%s member)') % (name, objectname)


class LSTraitTag(LSTag):
    """Description of a tag within a trait (require, provide).
    """
    def get_signature_prefix(self, sig):
        return self.objtype + ' '

    def get_index_text(self, objectname, name_obj):
        name = name_obj[0].split('->')[-1]
        return _('%s() (%s %s)') % (name, objectname, self.objtype)


class LSXRefRole(XRefRole):
    """Provides cross reference links for Lasso objects.
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
    """Lasso language domain.
    """
    name = 'ls'
    label = 'Lasso'
    object_types = {
        'method':  ObjType(l_('method'),  'meth'),
        'member':  ObjType(l_('member'),  'meth'),
        'provide': ObjType(l_('provide'), 'meth'),
        'require': ObjType(l_('require'), 'meth'),
        'type':    ObjType(l_('type'),    'type'),
        'trait':   ObjType(l_('trait'),   'trait'),
        'thread':  ObjType(l_('thread'),  'thread'),
    }
    directives = {
        'method':  LSTag,
        'member':  LSTag,
        'provide': LSTraitTag,
        'require': LSTraitTag,  # name and signature only
        'type':    LSDefinition,
        'trait':   LSDefinition,
        'thread':  LSDefinition,
    }
    roles = {
        'meth':   LSXRefRole(),
        'type':   LSXRefRole(),
        'trait':  LSXRefRole(),
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
