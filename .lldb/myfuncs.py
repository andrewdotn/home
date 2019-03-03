from __future__ import print_function

import argparse
import shlex

import lldb

def fgrep_output(debugger, command, result, internal_dict):
    args = shlex.split(command)

    parser = argparse.ArgumentParser(prog='fgrep_output')
    parser.add_argument('fixed_string')
    parser.add_argument('command')
    options = parser.parse_args(args)

    res = lldb.SBCommandReturnObject()
    interp = debugger.GetCommandInterpreter()
    interp.HandleCommand(options.command, res)
    # print(repr(res))
    for line in res.GetOutput().split("\n"):
        if options.fixed_string in line:
            print(line)

def __lldb_init_module(debugger, internal_dict):
    module = __name__
    for command in ['fgrep_output']:
        debugger.HandleCommand('command script add -f {0}.{1} {1}'.format(
            module, command))
    print('The "{}" python command has been installed and is ready for use.'
          .format(module))
