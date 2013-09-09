#!/usr/bin/lasso9
/*[*/
/*
  Given a set of Lasso files or element names, outputs reference docs for each
  element for the Lasso domain for Sphinx. Since Lasso defaults to not retaining
  docComments, prefix with `env LASSO9_RETAIN_COMMENTS=1` when running from the
  command line. Generates reST markup like so:

  method:: signature
    docstring                     <-- words from docComment before @attribute lines
    :param name: description          <-- from "@param name description" in docComment
    :param type name: description     <-- type inserted if not ::any
    :param ...: description        <-- if signature has ... & docComment has @param rest or @param ...
    :param restname: description    <-- if signature has ...restname & docComment has @param restname
    :return: description          <-- from "@return description" in docComment
    :rtype: return type           <-- rtype inserted if return type not ::any
    :see: resource            <-- from "@see resource" in docComment
  trait:: name
    docstring
    :see: resource
    :import: traitname
    require:: signature
      ...                 <-- same as method::
    provide:: signature
      ...                 <-- same as method::
  type:: name
    docstring
    :see: resource
    :parent: typename
    member:: signature
      ...                 <-- same as method::
    :import: traitname
    provide:: signature
      ...                 <-- same as method::
  thread:: name
    ...               <-- same as type::

  Known limitations:
  - won't generate :import: lines for traits added later with ->addTrait
  - Lasso applies a docComment to only the first require statement in a group
  - Lasso has no way to show which member methods are public/protected/private (#7494)
  - a trait will see its requires disappear as imports are added (#7581)
  - data elements and therefore automatic getters/setters can't have docstrings
  - doesn't detect redefinitions of existing methods or members

  To-do:
  - warn when finding @param lines with no matching parameter
  - replace auto-collect with output to variable
  - add line-wrapping to signatures and attribute descriptions
  - add detection of members added to built-in types
  - cut first line of description if it matches the name of the docComment's element
  - onCreate methods should be listed first
*/

not sys_getenv('LASSO9_RETAIN_COMMENTS') ?
  fail('This program requires the LASSO9_RETAIN_COMMENTS environment variable be set to 1')
$argc == 1 ?
  fail('Specify --find=<type or trait regex> and/or one or more Lasso files to read as arguments')

/**!
  Type containing description and attributes of a given tag's doc comment.
  @author   Eric Knibbe
  @see      http://lassoguide.com/syntax/literals.html
  @see      http://sphinx-doc.org/domains.html#info-field-lists
*/
define docObject => type {
  data indent             // string to use as indent
  data description = ''   // first block of text before @attribute lines
  data paramsorder = array()  // each param's name, since params is an unordered container
  data paramskeyed = array()  // whether each param is a keyword parameter
  data params = map()     // each is ('pname' = pair(::ptype, 'pdesc')) from #element & @param lines
  data others = array()   // each is (pair('attribute', 'value')) from other @attribute lines
  data result = pair()    // (::rtype, 'rdesc') from #element & @return

  // #element can be a tag or signature, or anything supporting ->docComment
  public onCreate(element, indent::string='   ') => {
    .'indent' = #indent

    // fill params with names & types from ->paramDescs, ->restName, ->returnType
    // only applies to signatures, as types & traits won't have params or return
    if (#element->type == ::signature) => {
      with parray in #element->paramDescs
      do {
        .'paramsorder'->insert(#parray->first)
        .'paramskeyed'->insert(#parray->get(3)->bitTest(2))
        .'params'->insert(pair(#parray->first, pair(#parray->second, null)))
      }
      if (#element->restName != void) => {
        .'paramsorder'->insert(#element->restName == ::rest ? '...' | #element->restName->asString)
        .'params'->insert(pair(
            (#element->restName == ::rest ? '...' | #element->restName->asString),
            pair(::rest, null)
        ))
      }
      #element->returnType != ::any ? .'result'->first = #element->returnType
    }

    // fill params & others with data parsed from @attribute lines
    local(      // remove delimiters, trim & collapse whitespace but preserve paragraph breaks
      components = #element->docComment->removeLeading('/**!')
                                        &removeTrailing('*/')
                                        &removeTrailing('*')
                                        &replace(regexp('[ \\t]*(\\n|\\r\\n?)[ \\t]*'),'\n')
                                        &replace(regexp('[ \\t]+|(?<!\\n)\\n(?!\\n)'),' ')
                                        &replace(regexp('^@'),' @') // needs leading space if no description
                                        &split(' @')
    )   // array('description','param name Words about parameter','return Words about result')
    #components->first != null ? .'description' = #components->first->trim&;
    // loop through #components, splitting each on space and checking the first result
    with item in #components
    skip 1
    let words = #item->trim&split(' ')  // array('param','name','Words','about','parameter')
    let word1 = string_removetrailing(#words->first, ':')   // attribute type
    let word2 = string_removetrailing(#words->second, ':')  // name if attribute is param, otherwise description
    do {
      local(ptype = ::any)
      if (#word1 == 'param') => {
        protect => {        // in case name following @param is misspelled
          // first check if the given @param name matches the signature's ->restName
          if (#element->restName != void &&
              #word2 == #element->restName ||
              #word2 == '...') => {
            .'params'->insert(pair(
                (#word2 == 'rest' ? '...' | #word2),
                pair(#ptype, #words->remove(1,2)&join(' '))
            ))
          else
            #ptype = .'params'->get(#word2)->first
            .'params'->insert(pair(#word2, pair(#ptype, #words->remove(1,2)&join(' '))))
          }
        }
      else (#word1 == 'return')
        .'result'->second = #words->remove(1)&join(' ')
      else
        .'others'->insert(pair(#word1, #words->remove(1)&join(' ')))
      }
    }
  }

  /**! @return description block, wrapped and indented */
  public description()::string => {
    return (.'description'->size != 0 ? string_wrap(.'description', .'indent') + '\n' | '')
  }

  /**! @return parameter descriptions as roles */
  public params()::string => {
    local(attributes = '')
    protect => {
      pairup(.'paramsorder', .'paramskeyed')->forEach => {
        local(name = #1->first)
        #attributes->append(.'indent' + ':param')
        if (.'params'->get(#name)->first != ::any &&
            .'params'->get(#name)->first != ::rest) => {
          #attributes->append(' ' + .'params'->get(#name)->first->asString)
        }
        #attributes->append(' ' + (#1->second ? '-') + #name->asString + ':')
        if (.'params'->get(#name)->second != null) => {
          #attributes->append(' ' + .'params'->get(#name)->second->asString + '\n')
        else
          #attributes->append('\n')
        }
      }
    }
    return #attributes
  }

  /**! @return other doc comment attributes as roles */
  public others()::string => {
    local(attributes = '')
    if (.'result'->second != null) => {
      #attributes->append(.'indent' + ':return: ' + .'result'->second->asString + '\n')
    }
    if (.'result'->first != null) => {
      #attributes->append(.'indent' + ':rtype: `' + .'result'->first->asString + '`\n')
    }
    with attr in .'others'
    do {
      #attributes->append(.'indent' + ':' + #attr->first + ': ' + #attr->second + '\n')
    }
    return #attributes
  }
}

/**!
  Wraps the given string to the specified length.
  Modified to accept a string for indenting each line.
  (indent was originally a keyword parameter, but issue #7408 prevented that)
  @see http://www.lassosoft.com/tagswap/detail/string_wrap
*/
define string_wrap(
    text,
    indent::string='',
    length::integer=80,
    linebreak::string='\n',
    trim::boolean=true,
    -priority='replace'
    ) => {
  local(
    'in' = string(#text)->trim&,
    'out' = string
  )
  #length -= #indent->size + 1
  #in->replace('\r\n','\n')&replace('\r','\n')
  iterate(#in->split('\n'), local('i')) => {
    local('line' = #i)
    #trim ? #line->trim
    if(#line->size < #length) => {
      #out += #indent + #line + #linebreak
    else
      local(
        'lineIn' = #line,
        'lineOut' = string
      )
      while(#lineIn->size > #length) => {
        local('offset' = #length)
        while(#lineIn->size > #offset &&
              #offset > 0 &&
              !#lineIn->isspace(#offset)) => {
          #offset -= 1
        }
        #offset == 0 ? #offset = #length
        local('chunk') = #lineIn->substring(1, #offset)
        #lineOut += #indent + #chunk + #linebreak
        #lineIn->removeleading(#chunk)
      }
      #lineIn->size ? #lineOut += #indent + #lineIn + #linebreak
      #out += #lineOut
    }
  }
  return(#out)
}

/**!
  A reST-friendly output method for the signature type.
  @return   signature as reST string
  @author   Eric Knibbe
*/
define signature->asReString => {
  local(
    output = .methodName->asString + '(',
    num = 0,
    opt = false,
    size = .paramDescs->size
  )
  with param in .paramDescs
  let name = #param->get(1)
  let type = #param->get(2)
  let flags = #param->get(3)  // 1st bit: optional param, 2nd bit: keyword param
  do {
    if (!#opt && #flags->bitTest(1)) => {
      #opt = true
      #output->append('[')
    }
    if (#opt && !#flags->bitTest(1)) => {
      #opt = false
      #output->append(']')
    }
    #num != 0 ?
      #output->append(', ')
    #num++
    #flags->bitTest(2) ?
      #output->append('-')
    #output->append(#name->asString)
    #type != ::any ?
      #output->append('::' + #type->asString)
    #opt && #num==#size && !.restName ?
      #output->append(']')
    !#opt && #num==#size && .restName ?
      #output->append('[')
  }
  if (.restName) => {
    #size == 0 ?
      #output->append('[') | #output->append(', ')
    #output->append('...')
    .restName != ::rest ?
      #output->append(.restName->asString)
    #output->append(']')
  }
  #output->append(')')
  .returnType != ::any ?
    #output->append('::' + .returnType)
  return #output
}

/**!
  Write docs for a given tag.
  @param element    the subject of the docs, can be ::tag or ::signature
  @param directive  what directive to use, e.g. type::
  @param nesting    what level to nest the output (0 = no nesting)
  @author   Eric Knibbe
*/
define writeDocs(element, directive::string, nesting::integer=0) => {^

  // check if #element is a thread or thread's type
  if (#element->type == ::tag) => {
    if (#element->asString->endsWith('_thread$')) => {
      #directive = 'thread'
    else (#element->gettype->parent->asString->endsWith('_thread$'))
      #directive = 'thread'
      #element = #element->gettype->parent  // given thread's type, switch to thread
    }
  }

  local(
    indent = '   ',
    docElement = docObject(#element, #indent*(#nesting+1))
  )

  // initial directive
  '\n' + #indent*#nesting + '.. ' + #directive + ':: '
  #element->type == ::signature ?
    #element->asReString + '\n\n' | #element->asString->removeTrailing('_thread$')& + '\n\n'

  // items from docComment
  #docElement->description
  #docElement->params
  #docElement->others

  if (#directive == 'trait') => {

    // roles for imported traits
    if (#element->getType->subTraits->size != 0) => {^
      local(importlist =
        with trait in #element->getType->subTraits
        order by #trait->asString
        select #trait
      )
      #indent*(#nesting+1) + ':import: `' + #importlist->join('`, `') + '`\n'
    ^}

    // require directive
    with require in #element->getType->requires
    where #require->typeName == #element
    do {^
      writeDocs(#require, 'require', #nesting+1)
    ^}

    // provide directive
    with provide in #element->getType->provides
    where #provide->typeName == #element
    do {^
      writeDocs(#provide, 'provide', #nesting+1)
    ^}

  else (#directive == 'type' || #directive == 'thread')

    // role for parent type
    if (#element->getType->parent != ::null) => {^
      #indent*(#nesting+1) + ':parent: `' + #element->getType->parent->asString + '`\n'
    ^}

    // switch back to thread's type
    #directive == 'thread' ? #element = tag(#element->asString->removeTrailing('_thread$')&)

    // trait block within type
    if (#element->getType->trait != void &&
        #element->getType->trait->asString != 'any' &&
        #element->getType->trait->asString !>> #element->getType->parent->asString
        ) => {
      local(imports = array())
      if (#element->getType->trait->subTraits->size != 0 &&
          #element->getType->trait->subTraits->first->asString != '_'
          ) => {
        if (#element->getType->trait->subTraits->first->asString->isAlpha(1)) => {
          local(traitlist = #element->getType->trait->subTraits)
        else    // addTrait has been used on this type
          local(traitlist = #element->getType->trait->subTraits->first->subtraits)
        }
        with each in #traitlist
        where #each != any
        do {
          if (#each->asString->isalpha(1)) => {
            #imports->insert(#each)
          else (#each->asString == ('_' || '$$trait.' + #element->asString))
            #imports->merge(#each->subTraits)
          }
        }
      }

      if (#imports->size) => {^
        local(importlist =
          with trait in #imports
          order by #trait->asString
          select #trait
        )
        #indent*(#nesting+1) + ':import: `' + #importlist->join('`, `') + '`\n'
      ^}

      // trait provide within type
      with provide in #element->getType->trait->provides
      where #provide->typeName->asString == '$$trait.' + #element->asString
      order by #provide->methodName     // since the ordering can be random
      do {^
        writeDocs(#provide, 'provide', #nesting+1)
      ^}
    }

    // member directive
    with member in #element->getType->listMethods
    let m_name = #member->methodName->asString
    where #member->typeName == #element
    where not #m_name->beginsWith("'") // skip 'x'() but not _x() x=() x()
    order by #m_name->isAlpha(1), #m_name
    do {^
      writeDocs(#member, 'member', #nesting+1)
    ^}

  }

^}

/*
  This script is run with arguments specifying language elements and/or files to
  generate reST markup for. Each new type, trait, and method can be read off the
  end of the lists returned by the sys_list* methods.
*/
iterate($argv) => {
  loop_count == 1 ? loop_continue
  $argv->first->endsWith(loop_value) ? loop_continue  // prevent script from reading itself
  local(
    typecount_orig = sys_listTypes->size,     // staticarray of tags
    traitcount_orig = sys_listTraits->size,   // staticarray of tags
    methodcount_orig = sys_listUnboundMethods->size,  // staticarray of signatures
    currentfile = file(loop_value),
    typelist = array(),
    traitlist = array()
  )

  // if argument is --find=<type or trait regex>, include the results in the output
  if (loop_value->beginsWith('--find=')) => {
    local(findarg = '^(?![$])' + loop_value->sub(8)->replace('"','')&replace("'",'')&)
    sys_listTypes->forEach => {
      regexp(-find=#findarg, -input=#1->asString, -ignoreCase)->matches ?
        stdoutnl('\n' + '='*#1->asString->size +
                 '\n' + #1->asString +
                 '\n' + '='*#1->asString->size +
                 '\n' + writeDocs(#1, 'type'))
    }
    sys_listTraits->forEach => {
      regexp(-find=#findarg, -input=#1->asString, -ignoreCase)->matches ?
        stdoutnl('\n' + '='*#1->asString->size +
                 '\n' + #1->asString +
                 '\n' + '='*#1->asString->size +
                 '\n' + writeDocs(#1, 'trait'))
    }
    loop_continue
  }

  // read each specified file
  sourcefile(#currentfile, -autoCollect=false)->invoke
  stdoutnl(
    '\n' + '='*#currentfile->name->size +
    '\n' + #currentfile->name +
    '\n' + '='*#currentfile->name->size
  )    // print the filename as a heading

  // create lists of new types & traits
  with type in sys_listTypes
  skip #typecount_orig
  where not #type->asString->endsWith('$')  // skip thread objects
  do {
    #typelist->insert(#type)
  }
  with trait in sys_listTraits
  skip #traitcount_orig
  where not #trait->asString->beginsWith('$') // skip traits made by combining other traits
  do {
    #traitlist->insert(#trait)
  }

  // write markup for new unbound methods (must occur before writing types, or this file's methods are included)
  with method in sys_listUnboundMethods
  skip #methodcount_orig
  where #method->methodName->asString->isalpha(1)     // skip private methods
  where not #typelist->contains(#method->methodName)  // skip auto-generated type & trait methods
  where not #traitlist->contains(#method->methodName)
  do {
    stdoutnl(writeDocs(#method, 'method'))
  }

  // write markup for new types
  with type in #typelist
  do {
    stdoutnl(writeDocs(#type, 'type'))
  }

  // write markup for new traits
  with trait in #traitlist
  do {
    stdoutnl(writeDocs(#trait, 'trait'))
  }
}
