# coding: UTF-8

from __future__ import print_function

import argparse
import shlex
import struct

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
    for line in res.GetOutput().split("\n"):
        if options.fixed_string in line:
            print(line)

DECLS = {
    'CCCryptorGCM': [
        'op', 'alg', 'key', 'keyLength', 'iv', 'ivLen', 'aData', 'aDataLen',
        'dataIn', 'dataInLength', 'dataOut', 'tagOut', 'tagLength',
    ],
    'ccpbkdf2_hmac': [
        'digest_info', 'passwordLen', 'password', 'saltLen', 'salt',
        'iterations', 'dkLen', 'dk',
    ],
    # This is the one in AppleKeyStore
    'rfc3394_unwrap': [
        'kek', 'kek_size', 'iv', 'unknown', 'wrapped', 'wrapped_size', 'unwrapped', '&unwrapped_size',
    ],
    'cccbc_one_shot': [
        'struct ccmode_cbc *mode', 'key_len', 'key', 'iv', 'nblocks', 'in',
        'out',
     ],
    'unwrap_key_generic': [
        'param1', 'kek', 'kek_size', 'wrapped', 'wrapped_size', 'param6', 'param7', 'param8', 'param9',
    ],
}

def arg_name(frame, i):
    func_name = frame.GetDisplayFunctionName()
    decl = DECLS.get(func_name, None)
    if decl:
        return decl[i]
    return "arg{}".format(i)

def get_regions(process):
    swig_regions = process.GetMemoryRegions()
    n = swig_regions.GetSize()
    region_info = []
    for i in range(n):
        info = lldb.SBMemoryRegionInfo()
        swig_regions.GetMemoryRegionAtIndex(i, info)

        # s = lldb.SBStream()
        # info.GetDescription(s)

        region_info.append((info.GetRegionBase(), info.GetRegionEnd()))

    return region_info

def print_value_maybe_pointer(debugger, frame, value, arg_index, desc, regions):
    name = arg_name(frame, arg_index)

    print("{:8} = 0x{:<16x} {:<20} {}".format(desc, value, value, name))

    if len(regions) == 0:
        if value & 0xffffff0000000000 == 0xffffff0000000000:
            debugger.HandleCommand("x {:x}".format(value))

    for start, end in regions:
        if value >= start and value <= end:
            debugger.HandleCommand("x {:x}".format(value))

def dump_args(debugger, command, result, internal_dict):
    args = shlex.split(command)
    parser = argparse.ArgumentParser(prog='dump_args')
    parser.add_argument('nargs', type=int)
    options = parser.parse_args(args)

    registers = ["rdi", "rsi", "rdx", "rcx", "r8", "r9"]

    target = lldb.debugger.GetSelectedTarget()
    process = target.process
    frame = process.GetSelectedThread().GetSelectedFrame()

    regions = get_regions(process)

    for i in range(min(options.nargs, len(registers))):
        reg_list = frame.GetRegisters()
        # The first register list, possibly called "General Purpose Registers" or "general"
        gp_reg_list = reg_list.GetValueAtIndex(0)
        reg = gp_reg_list.GetChildMemberWithName(registers[i])
        value = int(reg.value, 16)

        print_value_maybe_pointer(debugger, frame, value, i,
                                  "$" + registers[i], regions)

    if options.nargs > len(registers):
        for i in range(len(registers), options.nargs):
            # Assuming all 8-byte args for now
            offset = (i - len(registers)) * 8
            # “Get the Canonical Frame Address for this stack frame. This is the
            # “DWARF standard's definition of a CFA, a stack address that
            # “remains constant throughout the lifetime of the function.”
            addr = frame.GetCFA() + offset
            error = lldb.SBError()
            memory = process.ReadMemory(addr, 8, error)
            value = struct.unpack('Q', memory)[0]

            print_value_maybe_pointer(debugger, frame, value, i,
                                      "*(rbp+{}={:x})".format(16+offset, addr), regions)

# TODO: sometimes this hangs, I think when
#  `settings set stop-disassembly-display always` is active
def trace_execution(debugger, command, result, internal_dict):
    target = debugger.GetSelectedTarget()
    debugger.SetAsync(False)
    trace_execution_of(target)

    # listener = debugger.GetListener()
    # event = lldb.SBEvent()
    # if listener.WaitForEvent(options.event_timeout, event):


def __lldb_init_module(debugger, internal_dict):
    module = __name__
    for command in ['fgrep_output', 'trace_execution', 'dump_args']:
        debugger.HandleCommand('command script add -f {0}.{1} {1}'.format(
            module, command))
    print('The "{}" python module has been installed and is ready for use.'
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

