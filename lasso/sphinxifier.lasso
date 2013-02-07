#!/usr/bin/lasso9

/*
  Generates reference docs for the as-yet-unwritten Sphinx Lasso domain from code.
  Prefix with LASSO9_RETAIN_COMMENTS=1 when running from terminal.
  Generates reST markup like so:

  method:: signature
    docstring                     <-- words from docComment before @attribute lines
    :param name: description          <-- from "@param name description" in docComment
    :param type name: description     <-- type inserted if not ::any
    :param rest ...: description      <-- if signature has ... & docComment has @param rest or @param ...
    :param rest rname: description    <-- if signature has ...rname & docComment has @param rname
    :return: description          <-- from "@return description" in docComment
    :return type: description     <-- type inserted if not ::any
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
    method:: signature
      ...                 <-- same as method::
    :import: traitname
    provide:: signature
      ...                 <-- same as method::
  thread:: name
    ...               <-- same as type::

  - no way to tell if member methods are public/protected/private
  - only line-wraps description blocks, not signatures or attribute descriptions
  - needs a way to warn of misspelled @params
  - replace auto-collect with output to file
  - may need some more line breaks added after Lasso domain is written
  - could support special attributes, e.g. @example after which spacing is preserved
  - couldn't test ->addTrait on traits due to segfault (bug #7491, fixed for 9.2.6)

  <?
*/

not sys_getenv('LASSO9_RETAIN_COMMENTS') ?
  fail('This program requires the LASSO9_RETAIN_COMMENTS environment variable be set to 1')

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
  data params = map()     // each is ('pname' = pair(::ptype, 'pdesc')) from #element & @param lines
  data others = array()   // each is (pair('attribute', 'value')) from other @attribute lines
  data result = pair()    // (::rtype, 'rdesc') from #element & @return

  // #element can be a tag or signature, or anything supporting ->docComment
  public onCreate(element, indent::string='   ') => {
    .'indent' = #indent

    // fill params with names & types from ->paramDescs, ->restName, ->returnType
    // only applies to signatures, as types & traits won't have params or return
    if (#element->type == ::signature)
      with parray in #element->paramDescs
      do {
        .'paramsorder'->insert(#parray->first)
        .'params'->insert(pair(#parray->first, pair(#parray->second, null)))
      }
      if (#element->restName != void)
        .'paramsorder'->insert(#element->restName == ::rest ? '...' | #element->restName->asString)
        .'params'->insert(pair(
          (#element->restName == ::rest ? '...' | #element->restName->asString),
          pair(::rest, null)
        ))
      /if
      #element->returnType != ::any ?
        .'result'->first = #element->returnType
    /if

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
    #components->first != null ?
      .'description' = #components->first   // blew away the string when I put trim here
    .'description'->trim
    // loop through #components, splitting each on space and checking the first result
    with item in #components
    skip 1
    let words = #item->trim&split(' ')  // array('param','name','Words','about','parameter')
    let word1 = #words->first       // type of attribute
    let word2 = #words->second      // name if ->first is param, otherwise description
    do {
      local(ptype = ::any)
      if (#word1 == 'param')
        protect => {        // in case name following @param is misspelled
          // first check if the given @param name matches the signature's ->restName
          if (#element->restName != void && (#word2 == '...' || #word2 == #element->restName))
            .'params'->insert(pair(
              (#word2 == 'rest' ? '...' | #word2),
              pair(::rest, #words->remove(1,2)&join(' '))
            ))
          else
            #ptype = .'params'->get(#word2)->first
            .'params'->insert(pair(#word2, pair(#ptype, #words->remove(1,2)&join(' '))))
          /if
        }
      else (#word1 == 'return')
        .'result'->second = #words->remove(1)&join(' ')
      else
        .'others'->insert(pair(#word1, #words->remove(1)&join(' ')))
      /if
    }
  }

  /**! @return description block, wrapped and indented */
  public description()::string => {
    return (.'description'->size != 0 ? string_wrap(.'description', -indent=.'indent') | '')
  }

  /**! @return parameter descriptions as roles */
  public params()::string => {
    local(attributes = '')
    protect => {
      .'paramsorder'->forEach => {
        #attributes->append(.'indent' + ':param')
        .'params'->get(#1)->first != ::any ?
          #attributes->append(' ' + .'params'->get(#1)->first->asString)
        #attributes->append(' ' + #1->asString + ':')
        .'params'->get(#1)->second != null ?
          #attributes->append(' ' + .'params'->get(#1)->second->asString + '\n')
          | #attributes->append('\n')
      }
    }
    return #attributes
  }

  /**! @return other doc comment attributes as roles */
  public others()::string => {
    local(attributes = '')
    if (.'result'->first != null || .'result'->second != null)
      #attributes->append(.'indent' + ':return')
      .'result'->first != null ?
        #attributes->append(' ' + .'result'->first->asString)
      #attributes->append(': ' + .'result'->second->asString + '\n')
    /if
    with attr in .'others'
    do {
      #attributes->append(.'indent' + ':' + #attr->first + ': ' + #attr->second + '\n')
    }
    return #attributes
  }
}

/**!
  Wraps a string to the specified length.
  Modified to accept a string for indenting each line.
  @see http://www.lassosoft.com/tagswap/detail/string_wrap
*/
define_tag(
    'wrap',
    -namespace='string_',
    -req='text', -copy,
    -opt='indent', -type='string',
    -opt='length', -copy, -type='integer',
    -opt='linebreak', -type='string',
    -opt='trim', -type='boolean',
    -priority='replace',
    -description='Wraps the given string to the specified length.'
);
    local(
        'in' = string(#text),
        'out' = string
    );
    !local_defined('indent') ? local('indent' = '');
    !local_defined('length') ? local('length' = 80);
    #length -= #indent->size + 1;
    !local_defined('linebreak') ? local('linebreak' = '\n');
    !local_defined('trim') ? local('trim' = true);
    #in->trim;
    #in->replace('\r\n','\n')&replace('\r','\n');
    iterate(#in->split('\n'), local('i'));
        local('line' = #i);
        #trim ? #line->trim;
        if(#line->size < #length);
            #out += #indent + #line + #linebreak;
        else;
            local(
                'lineIn' = #line,
                'lineOut' = string
            );
            while(#lineIn->size > #length);
                local('offset' = #length);
                while(#lineIn->size > #offset && #offset > 0 && !#lineIn->isspace(#offset));
                    #offset -= 1;
                /while;
                #offset == 0 ? #offset = #length;
                local('chunk') = #lineIn->substring(1, #offset);
                #lineOut += #indent + #chunk + #linebreak;
                #lineIn->removeleading(#chunk);
            /while;
            #lineIn->size ? #lineOut += #indent + #lineIn + #linebreak;
            #out += #lineOut;
        /if;
    /iterate;
    return(#out);
/define_tag;

/**!
  A reST-friendly output method for the signature type.
  @return   signature as reST string
  @author   Eric Knibbe
*/
define signature->reString => {
  local(
    output = .methodName->asString + '(',
    cnt = 0,
    opt = false,
    size = .paramDescs->size
  )
  with param in .paramDescs
  let name = #param->get(1)
  let type = #param->get(2)
  let flags = #param->get(3)  // 1st bit: optional param, 2nd bit: named param
  do {
    if (!#opt && #flags->bitTest(1))
      #opt = true
      #output->append('[')
    /if
    if (#opt && !#flags->bitTest(1))
      #opt = false
      #output->append(']')
    /if
    #cnt != 0 ?
      #output->append(', ')
    #cnt++
    #flags->bitTest(2) ?
      #output->append('-')
    #output->append(#name->asString)
    #type != ::any ?
      #output->append('::'+#type->asString)
    #flags->bitTest(1) && #cnt==#size ?
      #output->append(']')
  }
  if (.restName)
    #size != 0 ?
      #output->append(', ')
    #output->append('...')
    .restName != ::rest ?
      #output->append(.restName->asString)
  /if
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
  if (#element->type == ::tag)
    if (#element->asString->endswith('_thread$'))
      #directive = 'thread'
    else (#element->gettype->parent->asString->endswith('_thread$'))
      #directive = 'thread'
      #element = #element->gettype->parent  // given thread's type, switch to thread
    /if
  /if

  local(
    indent = '   ',
    docElement = docObject(#element, #indent*(#nesting+1))
  )

  // initial directive
  '\n' + #indent*#nesting + '.. ' + #directive + ':: '
  #element->type == ::signature ?
    #element->reString + '\n'
    | #element->asString->removeTrailing('_thread$')& + '\n'

  // items from docComment
  #docElement->description
  #docElement->params
  #docElement->others

  if (#directive == 'trait')

    // roles for imported traits
    if (#element->getType->subTraits->size != 0)
      with trait in #element->getType->subTraits
      order by #trait->asString
      do {^
        #indent*(#nesting+1) + ':import: ' + #trait->asString + '\n'
      ^}
    /if

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
    if (#element->getType->parent != ::null)
      #indent*(#nesting+1) + ':parent: ' + #element->getType->parent->asString + '\n'
    /if

    // method directive
    #directive == 'thread' ?      // switch back to thread's type
      #element = tag(#element->asString->removeTrailing('_thread$')&)
    with method in #element->getType->listMethods
    where #method->typeName == #element
    where #method->methodName->asString->isalpha(1) // skip 'x'() & _x() but not x=() or x()
    do {^
      writeDocs(#method, 'method', #nesting+1)
    ^}

    // trait block within type
    if (#element->getType->trait != void && #element->getType->trait->asString != 'any')
      local(imports = array())

      if (#element->getType->trait->asString->isAlpha(1)) // a single trait was added with addTrait
        #imports->insert(#element->getType->trait)
      else (#element->getType->trait->subTraits->size != 0) // one or more traits were added with import or addTrait
        with each in #element->getType->trait->subTraits
        where #each != any
        do {
          if (#each->asString->isalpha(1))
            #imports->insert(#each)
          else (#each->asString == ('_' || '$$trait.' + #element->asString))
            #imports->merge(#each->subTraits)
          /if
        }
      /if

      #imports->size ? '\n'
      with trait in #imports
      order by #trait->asString
      do {^
        #indent*(#nesting+1) + ':import: ' + #trait->asString + '\n'
      ^}

      // trait provide within type
      with provide in #element->getType->trait->provides
      where #provide->typeName->asString == '$$trait.' + #element->asString
      order by #provide->methodName     // since the ordering can be random
      do {^
        writeDocs(#provide, 'provide', #nesting+1)
      ^}
    /if

  /if

^}


/* Test cases */

/**! This doc comment is for a thread object.
  @see http://lassoguide.com/syntax/threading.html */
define counter_thread => thread {
  parent map
  data private val = 0
  public onCreate() => {}
  public onCreate(initValue::integer) => {
     .val = #initValue
  }
  public advanceBy(value::integer) => {
     .val += #value
     return .val
  }
}

//writeDocs(::any, 'trait')
//writeDocs(::array, 'type')
//writeDocs(::counter_thread, 'thread')
// can't write docs for an arbitrary method, as there's currently no way to fetch its ::signature

writeDocs(::docObject, 'type')

/*
with trait in sys_listTraits
where not #trait->asString->beginsWith('$') // traits made by combining other traits
where #trait->docComment->size > 0
do {^
  writeDocs(#trait, 'trait')
^}

with type in sys_listTypes
where not #type->asString->endsWith('$')  // thread objects
where #type->docComment->size > 0
do {^
  writeDocs(#type, 'type')
^}

// this is a staticarray of signatures; other two are tags
with method in sys_listUnboundMethods
let m_name = #method->methodName->asString
where not #m_name->endsWith('=')
where #m_name->isalpha(1)
where #method->docComment->size > 0
do {^
  writeDocs(#method, 'method')
^}
*/
