#!/usr/bin/env lasso9
/*
  Given a set of Lasso files or element names, outputs reference docs for each
  element for the Lasso domain for Sphinx. Since Lasso defaults to not retaining
  docComments, prefix with `export LASSO9_RETAIN_COMMENTS=1 LASSO9_NO_INTERPRETER=1`
  when running from the command line. Generates reST markup like so (with extra
  line breaks):

  method:: signature
    docstring                     <-- docComment content before @-prefixed attribute lines
    :param name: description          <-- from "@param name description" in docComment
    :param type name: description     <-- type inserted if not ::any
    :param ...: description        <-- if signature has ... & docComment has "@param rest" or "@param ..."
    :param restname: description    <-- if signature has ...restname & docComment has "@param restname"
    :return: description          <-- from "@return description" in docComment
    :rtype: return type           <-- rtype inserted if return type not ::any
    :see: resource            <-- from "@see resource" in docComment
  trait:: name
    docstring
    :see: resource
    :import: traitnames   <-- trait list inserted from `import` commands
    require:: signature
      ...                 <-- same as method::
    provide:: signature
      ...                 <-- same as method::
  type:: name
    docstring
    :see: resource
    :parent: typename     <-- parent type inserted from `parent` command
    :import: traitnames   <-- trait list inserted from `trait { }` block
    provide:: signature
      ...                 <-- same as method::
    member:: signature
      ...                 <-- same as method::
  thread:: name
    ...               <-- same as type::

  Known limitations:
  - won't generate :import: lines for traits added later with ->addTrait
  - Lasso applies a docComment to only the first require statement in a group
  - data elements and therefore automatic getters/setters can't have docstrings
  - little error handling, e.g. when finding @param lines with no matching parameter
  - can't fetch default parameter values from the code; must be added to output manually
  - uses auto-collect; might be faster with output to variable instead
*/

/**!
  Type containing description and attributes of a given tag's doc comment.
  @author   Eric Knibbe
  @see      http://lassoguide.com/syntax/literals.html
  @see      http://sphinx-doc.org/domains.html#info-field-lists
*/
define docObject => type {
  data indent               // string to use as indent
  data description = ''     // first block of text before @attribute lines
  data paramsorder = array  // each param's name, since params is an unordered container
  data paramskeyed = array  // whether each param is a keyword parameter
  data params = map         // each is ('pname' = pair(::ptype, 'pdesc')) from #element & @param lines
  data others = array       // each is (pair('attribute', 'value')) from other @attribute lines
  data result = pair        // (::rtype, 'rdesc') from #element & @return

  /**!
    @param element  can be a tag or signature, or anything supporting ->docComment
    @param indent   characters to use for indentation
  */
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
      components = #element->docComment->replace(regexp('^/\\*\\*!'),' ')
                                        &removeTrailing('*/')
                                        &removeTrailing('*')
                                        &replace(regexp('[ \\t]*(\\n|\\r\\n?)[ \\t]*'),'\n')
                                        &replace(regexp('[ \\t]+|(?<!\\n)\\n(?!\\n)'),' ')
                                        &replace(regexp('\\n+@'),' @') // first @ always needs leading space
                                        &split(' @')
    )   // array('description','param name Words about parameter','return Words about result')
    #components->first != null ? .'description' = #components->first->trim&;
    // loop through #components, splitting each on space and checking the first result
    with item in #components
    skip 1
    let words = #item->trim&split(' ')  // array('param','name','Words','about','parameter')
    let word1 = string_removetrailing(#words->first, ':')   // attribute type
    let word2 = string_removetrailing(string_removeleading(#words->second, '-'), ':')  // name if attribute is param, otherwise description
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
      #out->append(#indent + #line + #linebreak)
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
        local('chunk') = #lineIn->sub(1, #offset)
        #lineOut->append(#indent + #chunk + #linebreak)
        #lineIn->removeleading(#chunk)
      }
      #lineIn->size ? #lineOut->append(#indent + #lineIn + #linebreak)
      #out->append(#lineOut)
    }
  }
  return(#out)
}

/**!
  A reST-friendly output method for the signature type.
  @param withType            print member methods prefixed by their type instead of indented
  @param withSquareBrackets  surround optional parameters with square brackets
  @return   signature as reST string
  @author   Eric Knibbe
*/
define signature->asReString(-withType=false, -withSquareBrackets=false) => {
  local(
    output = .methodName->asString + '(',
    num = 0,
    opt = false,
    size = .paramDescs->size
  )
  #withType && .typename->asString->isAlpha(1) ?
    #output = .typename->asString + '->' + #output
  with param in .paramDescs
  let name = #param->get(1)
  let type = #param->get(2)
  let flags = #param->get(3)  // 1st bit: optional param, 2nd bit: keyword param
  do {
    if (!#opt && #flags->bitTest(1)) => {
      #opt = true
      #withSquareBrackets ?
        #output->append('[')
    }
    if (#opt && !#flags->bitTest(1)) => {
      #opt = false
      #withSquareBrackets ?
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
    not #withSquareBrackets && #flags->bitTest(1) ?
      #output->append('= ?')
    #opt && #num==#size && !.restName ?
      #withSquareBrackets ?
        #output->append(']')
    !#opt && #num==#size && .restName ?
      #withSquareBrackets ?
        #output->append('[')
  }
  if (.restName) => {
    #size > 0 ?
      #output->append(', ') | #withSquareBrackets ?
        #output->append('[')
    #output->append('...')
    .restName != ::rest ?
      #output->append(.restName->asString)
    #withSquareBrackets ?
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
  @param typed      value for asReString's withType param
  @param squarebrackets value for asReString's withSquareBrackets param
  @author   Eric Knibbe
*/
define writeDocs(element, directive::string, nesting::integer=0, -typed=false, -squarebrackets=false) => {^

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
    #element->asReString(-withType=#typed, -withSquareBrackets=#squarebrackets) + '\n\n'
    | #element->asString->removeTrailing('_thread$')& + '\n\n'

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
      local(imports = array)
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
    // refine to detect `data` candidates 
    with member in #element->getType->listMethods
    let m_name = #member->methodName->asString
    where #member->typeName == #element
    where not #member->flags->bitAnd(0x0C) // skip private and protected methods
    where not #m_name->beginsWith("'") // skip 'x'() but not _x() x=() x()
    order by #m_name->isAlpha(1), #m_name
    do {^
      writeDocs(#member, 'member', #nesting+(#typed? 0 | 1), -typed=#typed, -squarebrackets=#squarebrackets)
    ^}

  }

^}

/*
  This script is run with arguments specifying language elements and/or files to
  generate reST markup for. Each new type, trait, and method can be read off the
  end of the lists returned by the sys_list* methods.
*/
define usage(exit_status::integer=-1) => {
    local(cmd) = $argv->get(1)->lastComponent
    stdoutnl("\
usage: " + #cmd + " [options] [file paths]

    The " + #cmd + " command prints reST markup describing types, traits, and
    methods in the given files or loaded in the current Lasso installation.
    
    If one or more file paths are provided, only types, traits, and methods
    defined in the files and not already loaded into Lasso are printed.
    
    Must be run with the LASSO9_RETAIN_COMMENTS and LASSO9_NO_INTERPRETER
    environment variables set to 1.

Options
-------
    -m <string or regex pattern>
        Only print types, traits, and methods matching the given pattern.
    
    -typed
        Print member methods without indentation, prefixed with their type name.
    
    -squarebrackets
        Surround optional parameters in square brackets when printing signatures.
    
    -h
        Displays this help and exits."
    )
    sys_exit(#exit_status)
}

// default options
local(
  opts = $argv->asArray->remove(1,1)&,
  pattern = regexp(-find='^(?![$]).+', -ignoreCase),
  paths = array,
  typed = false,
  squarebrackets = false,
  type_skip = 0,
  trait_skip = 0, 
  method_skip = 0,
  typelist = array,
  traitlist = array,
  methodlist = array,
)

// ensure env var and arguments are provided
not sys_getenv('LASSO9_RETAIN_COMMENTS') || not sys_getenv('LASSO9_NO_INTERPRETER') || $argc == 1 ?
  usage

while(#opts->size > 0) => {
    match(bytes(#opts->first)) => {

    // -m: read the next argument and set it as the search pattern
    case(bytes('-m'))
      // ignore anything starting with $ and remove surrounding quotes
      #pattern->findpattern = '^(?![$])' + #opts(2)->replace('"','')&replace("'",'')&
      #opts->remove(1,1)

    // -typed: set #typed to true
    case(bytes('-typed'))
      #typed = true

    // -squarebrackets: set #squarebrackets to true
    case(bytes('-squarebrackets'))
      #squarebrackets = true

    // -h: print help and exit
    case(bytes('-h'))
      usage(0)

    // otherwise, assume the argument is a file name
    case
      #paths->insert(#opts->first)
    }
  #opts->remove(1,1)
}

// Load and register contents of $LASSO9_MASTER_HOME/LassoModules/
// database_initialize

// Load all of the libraries from builtins and lassoserver
// This forces all possible available types and methods to be registered
local(srcs =
  (:
    dir(sys_masterHomePath + '/LassoLibraries/builtins/')->eachFilePath,
    dir(sys_masterHomePath + '/LassoLibraries/lassoserver/')->eachFilePath
  )
)
with topLevelDir in delve(#srcs)
where not #topLevelDir->lastComponent->beginsWith('.')
do protect => {
  handle_error => {
//     stdoutnl('Unable to load: ' + #topLevelDir + ' ' + error_msg)
  }
  library_thread_loader->loadLibrary(#topLevelDir)
//   stdoutnl('Loaded: ' + #topLevelDir)
}

// if files were provided, take note of the currently-registered types and traits, read each file, and print only the new items
if (#paths->size > 0) => {

  local(
    type_skip = sys_listTypes->size,     // staticarray of tags
    trait_skip = sys_listTraits->size,   // staticarray of tags
    method_skip = sys_listUnboundMethods->size,  // staticarray of signatures
  )  

  with path in #paths
  let f = file(#path)
  do {
    if(not #f->exists) => {
      file_stderr->writeString(error_code_resNotFound + ':' + error_msg_resNotFound + ' - ' + #path + sys_eol)
      sys_exit(1)
    }
    sourcefile(#f, -autoCollect=false)->invoke
  }
}

// create lists of types, traits, methods to print
with type in sys_listTypes
skip #type_skip
where #type->asString->contains(#pattern, -ignoreCase)
where not #type->asString->endsWith('$')  // skip thread objects
do {
  #typelist->insert(#type)
}

with trait in sys_listTraits
skip #trait_skip
where #trait->asString->contains(#pattern, -ignoreCase)
where not #trait->asString->beginsWith('$') // skip traits made by combining other traits (redundant)
do {
  #traitlist->insert(#trait)
}

with method in sys_listUnboundMethods
skip #method_skip
where #method->asString->contains(#pattern, -ignoreCase)
where #method->methodName->asString->isalpha(1)     // skip private methods
where not #typelist->contains(#method->methodName)  // skip auto-generated type & trait methods
where not #traitlist->contains(#method->methodName)
do {
  #methodlist->insert(#method)
}

// write out markup
with x in #typelist
do {
  stdoutnl('\n' + #x->asString +
       '\n' + '='*#x->asString->size)
  stdoutnl(writeDocs(#x, 'type', 0, -typed=#typed, -squarebrackets=#squarebrackets)) // must specify 3rd param due to #7408
}
with y in #traitlist
do {
  stdoutnl('\n' + #y->asString +
       '\n' + '='*#y->asString->size)
  stdoutnl(writeDocs(#y, 'trait', 0, -typed=#typed, -squarebrackets=#squarebrackets))
}
with z in #methodlist
do {
  stdoutnl(writeDocs(#z, 'method'))
}
