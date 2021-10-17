#!/usr/bin/env python3

"""
Fixup the ‘.dic’ and ‘.aff’ files (the sources for building a vim
spell-checking dictionary) mentioned on the command line to handle the
typographical replacements mentioned in the REPLACEMENTS dict below.
"""

import re
import sys

REPLACEMENTS = {"'": "’"}
# Normally it is an error if the character to be replaced occurs in a part
# of the file where we don’t know how to make it’s replacement behave the
# same. We don’t care about these directives (specified by regexes) though.
UNHANDLED_DIRECTIVE_PATTERNS = [r'^TRY\s', r'^COMMON\s', r'^REP\s', r'^#']

def apply_replacements(line):
    replline = line
    for k, v in REPLACEMENTS.items():
        replline = line.replace(k, v)
    return replline

def ungenerate(func):
    def func_aux(*args, **kwargs):
        return [line for line in func(*args, **kwargs)]
    return func_aux

@ungenerate
def transform_dic(lines):
    for i, line in enumerate(lines):
        yield line
        replline = apply_replacements(line)
        if (replline != line
                and (i == 0 or lines[i - 1] != replline)
                and (i >= len(lines) - 1 or lines[i + 1] != replline)
                and not line.startswith('#')):
            yield replline

def test_transform_dic():
    words = ["foo",
             "isn't",
             "bar",
             "ain't"]
    words2 = transform_dic(words)
    assert len(words2) == 6
    assert words2[2] == words2[1].replace("'", "’")
    words3 = transform_dic(words2)
    assert words2 == words3

@ungenerate
def transform_aff(lines):
    replacement_chars = frozenset("".join(REPLACEMENTS.keys()))
    aux = []
    def fixed_aux(aux):
        line0 = " ".join(aux[0].split()[:-1] + [str(len(aux) - 1)]) + "\n"
        return [line0] + aux[1:]

    expectedauxsize = 0
    for i, line in enumerate(lines + [""]):
        if aux and expectedauxsize == len(aux):
            # Grr! Can’t use name ‘line’ because it will override the loop
            # variable
            for line2 in fixed_aux(aux):
                yield line2
            aux = []
            expectedauxsize = 0

        if re.match(r'^SFX\s', line):
            if not aux:
                expectedauxsize = int(line.split()[-1]) + 1
            aux.append(line)
            replline = apply_replacements(line)
            if line != replline:
                aux.append(replline)
                expectedauxsize += 1
            continue

        if re.match(r'^SET\s', line):
            yield 'SET cp1252\n'
        elif re.match(r'^MIDWORD\s', line):
            yield line.strip() + "".join(REPLACEMENTS.values()) + "\n"
        elif i < len(lines):
            if (replacement_chars.intersection(set(line))
                    and not any(re.match(pat, line)
                            for pat in UNHANDLED_DIRECTIVE_PATTERNS)):
                raise Exception(
                        'Don’t know how to transform syntax for %s on line %d'
                        % (repr(line), i + 1))
            yield line

def test_transform_aff():
    words = ["SET ISO8859-1\n",
             "MIDWORD\t'\n",
             "\n",
             "SFX M Y 1\n",
             "SFX M   0     's         .\n",
             "\n",
             "SFX M Y 1\n",
             "SFX M   0     's         .\n",
             "SFX M Y 1\n",
             "SFX M   0     's         .\n"]
    words2 = transform_aff(words)
    expected_words2 = ["SET cp1252\n",
             "MIDWORD\t'’\n",
             "\n",
             "SFX M Y 2\n",
             "SFX M   0     's         .\n",
             "SFX M   0     ’s         .\n",
             "\n",
             "SFX M Y 2\n",
             "SFX M   0     's         .\n",
             "SFX M   0     ’s         .\n",
             "SFX M Y 2\n",
             "SFX M   0     's         .\n",
             "SFX M   0     ’s         .\n"]
    assert words2 == expected_words2

def transform_file(filename, transformer):
    with open(filename, 'r', encoding='cp1252') as dictionary:
        lines = dictionary.readlines()
    lines = transformer(lines)
    with open(filename, 'w', encoding='cp1252') as dictionary:
        dictionary.writelines(lines)

if __name__ == '__main__':
    filenames = sys.argv[1:]
    if not filenames:
        raise Exception('RTFSRC')

    for filename in filenames:
        if filename.endswith('.dic'):
            transform_file(filename, transform_dic)
        elif filename.endswith('.aff'):
            transform_file(filename, transform_aff)
        else:
            raise Exception("Don’t know how to transform %s" %
                    repr(filename))
