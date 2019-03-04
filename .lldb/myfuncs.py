# coding: UTF-8

from __future__ import print_function

import argparse
import shlex

import lldb

NON_COMMENT_LISTING_WIDTH = 60

# TODO: use template from upstream
# TODO: use result object
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

# TODO: sometimes this hangs, I think when
# `settings set stop-disassembly-display always` is active
def trace_execution(debugger, command, result, internal_dict):
    target = debugger.GetSelectedTarget()
    debugger.SetAsync(False)
    trace_execution_of(target)

    # listener = debugger.GetListener()
    # event = lldb.SBEvent()
    # if listener.WaitForEvent(options.event_timeout, event):


def __lldb_init_module(debugger, internal_dict):
    module = __name__
    for command in ['fgrep_output', 'trace_execution']:
        debugger.HandleCommand('command script add -f {0}.{1} {1}'.format(
            module, command))
    print('The "{}" python command has been installed and is ready for use.'
          .format(module))



class TraceStep:
    def __init__(self, thread_plan, dict):
        self.thread_plan = thread_plan
        # self.start_address = thread_plan.GetThread().GetFrameAtIndex(0).GetPC()

        self.count = 0

    def explains_stop(self, event):
        # We are stepping, so if we stop for any other reason, it isn't
        # because of us.
        if self.thread_plan.GetThread().GetStopReason() == lldb.eStopReasonTrace:
            return True
        else:
            return False

    def should_stop(self, event):
        print("step {}".format(self.count))
        print(event)

        self.count += 1

        if self.count > 10:
            return True

        return False

    def should_step(self):
        return True

def trace_execution_of(target):
    process = target.process
    thread = process.GetThreadAtIndex(0)

    last_frame_name = None
    next_pc = None
    instrs_handled = 0

    while instrs_handled < 100:
        instrs_handled += 1

        frame = thread.GetFrameAtIndex(0)
        prefix = '|' * len(thread.frames)

        # Extra space if a jump was taken
        if frame.GetPC() != next_pc:
            print(prefix)

        if frame.name != last_frame_name:
            print("{}Entering {}".format(prefix, frame))
            last_frame_name = frame.name

        instr_list = target.ReadInstructions(target.ResolveLoadAddress(frame.GetPC()), 1, 'intel')
        ins = instr_list.GetInstructionAtIndex(0)

        msg = '{}  0x{:016x}: {:8} {}'.format(prefix, frame.GetPC(), ins.GetMnemonic(target), ins.GetOperands(target))
        comment = ins.GetComment(target)
        if comment:
            if len(msg) < NON_COMMENT_LISTING_WIDTH:
                msg += ' ' * (NON_COMMENT_LISTING_WIDTH - len(msg))
            msg += '; ' + comment

        print(msg)

        next_pc = frame.GetPC() + ins.GetByteSize()

        thread.StepInstruction(False)

if __name__ == '__main__':
    import os.path

    DEMO_FILE = os.path.expanduser('~/projects/stickyfix/abi-fun/abifun1')


    debugger = lldb.SBDebugger.Create()
    debugger.SetAsync(False)

    target = debugger.CreateTarget(DEMO_FILE)

    # target.Create

    error = lldb.SBError()
    launch_params = [
        ('listener', debugger.GetListener()),
        ('argv', None),
        ('envp', None),

        ('stdin_path', None),
        ('stdout_path', None),
        ('stderr_path', None),

        ('working_directory', None),
        # SWIG blows up with “Wrong number of arguments” if this is None instead of 0
        ('launch_flags', 0),
        ('stop_at_entry', True),
        ('error', error),
    ]
    launch_args = list(it[1] for it in launch_params)

    process = target.Launch(*launch_args)

    if not process:
        print(error)
    else:
        print(process)
        state = process.GetState()

        print('Stopped? {}'.format(state == lldb.eStateStopped))

        trace_execution_of(target)

