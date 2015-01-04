#!/usr/bin/env python3

# Generate text for testing reST highlighters.

ascii = (
    'a',
    '0',
    '_',
    '~',
    '@',
    '#',
    '$',
    '%',
    '^',
    '&',
    '*s*',  # emphasis string
    '\*',   # escaped star
    '-',
    '(',
    '[',
    '{',
    '<',
    ')',
    ']',
    '}',
    '>',
    '|p|',  # substitution reference
    '\|',   # escaped pipe
    '+',
    '=',
    ':c:',  # role name
    '\:',   # escaped colon
    ';',
    '.',
    ',',
    '"',
    "'",
    '!',
    '?',
    '/',
    '`b`',  # interpreted text
    '``l``',# literal text
    '\`',   # escaped backtick
    ' ',
    '\\',   # escaping backslash
    '\\\\', # literal backslash
)
ascii_inline = (
    '*',    # star starts emphasis string
    '|',    # pipe starts substitution reference
    ':',    # colon starts role name
    '`',    # backtick starts interpreted text
)
seq = ['|   left', 'start', 'end', 'right']
delimiters = (
    ('[', ']_', 'footnote/citation reference'),
    ('|', '|', 'substitution'),
    (':', ': ', 'field marker/directive option'),
    (':', ':', 'role'),
    ('_`', '`', 'inline internal target'),
    ('`', '`', 'interpreted text/phrase reference'),
    ('', '_', 'hyperlink reference'),
)

for d1, d2, dname in delimiters:
    seqstart = ('\n ' if d2 == ': ' else seq[0])

    if d2 == '`':
        print('\n.. default-role:: strong\n')
        seq[3] += '`'
    if d2 == '|':
        seq[3] += '|'

    t = '`text`' if d2 == ':' else ''
    print('\n'+seqstart, d1+seq[1]+seq[2]+d2+t, seq[3])

    if d2 != ': ':
        print('\nbefore start - '+dname+'\n')
        for i in ascii:
            print(seqstart, i+d1+seq[1]+seq[2]+d2+t, seq[3])
    if d1:
        print('\nafter start - '+dname+'\n')
        for i in ascii + ascii_inline:
            print(seqstart, d1+i+seq[1]+seq[2]+d2+t, seq[3])

    print('\nwithin - '+dname+'\n')
    for i in ascii + ascii_inline:
        print(seqstart, d1+seq[1]+i+seq[2]+d2+t, seq[3])
    if d1:
        print('\nwithin following delimiter - '+dname+'\n')
        for i in ascii:
            print(seqstart, d1+seq[1]+d1+i+seq[2]+d2+t, seq[3])
        if d2 == '`':
            print('\nwithin following delimiter & underscore - '+dname+'\n')
            for i in ascii:
                print(seqstart, d1+seq[1]+d2+'_'+i+seq[2]+d2+t, seq[3])
        print('\nwithin following escaped delimiter - '+dname+'\n')
        for i in ascii:
            print(seqstart, d1+seq[1]+'\\'+d1+i+seq[2]+d2+t, seq[3])

    print('\nbefore end - '+dname+'\n')
    for i in ascii + ascii_inline:
        print(seqstart, d1+seq[1]+seq[2]+i+d2+t, seq[3])
    if d2:
        print('\nafter end - '+dname+'\n')
        for i in ascii:
            print(seqstart, t+d1+seq[1]+seq[2]+d2+i, seq[3])
    if d2 == '|' or  d2 == ':' or  d1 == '`' or  d2 == '_':
        print('\nafter end and underscore - '+dname+'\n')
        for i in ascii:
            print(seqstart, t+d1+seq[1]+seq[2]+d2+'_'+i, seq[3])
    if d2 == '|' or  d2 == ':':
        print('\nafter end and two underscores - '+dname+'\n')
        for i in ascii:
            print(seqstart, t+d1+seq[1]+seq[2]+d2+'__'+i, seq[3])
