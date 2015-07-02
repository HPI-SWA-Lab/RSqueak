import os
from spyvm import model, error
from spyvm.plugins.plugin import Plugin
from spyvm.util.system import IS_WINDOWS


DebuggingPlugin = Plugin()

DebuggingPlugin.userdata['stop_ui'] = False
def stop_ui_process():
    DebuggingPlugin.userdata['stop_ui'] = True

# @DebuggingPlugin.expose_primitive(unwrap_spec=[object])
# def trace(interp, s_frame, w_rcvr):
#     interp.trace = True
#     return w_rcvr

# @DebuggingPlugin.expose_primitive(unwrap_spec=[object])
# def untrace(interp, s_frame, w_rcvr):
#     interp.trace = False
#     return w_rcvr


if IS_WINDOWS:
    def fork():
        raise NotImplementedError("fork on windows")
else:
    fork = os.fork


@DebuggingPlugin.expose_primitive(unwrap_spec=[object])
def trace_proxy(interp, s_frame, w_rcvr):
    interp.trace_proxy.activate()
    return w_rcvr

@DebuggingPlugin.expose_primitive(unwrap_spec=[object])
def untrace_proxy(interp, s_frame, w_rcvr):
    interp.trace_proxy.deactivate()
    return w_rcvr

@DebuggingPlugin.expose_primitive(unwrap_spec=[object])
def halt(interp, s_frame, w_rcvr):
    from rpython.rlib.objectmodel import we_are_translated
    from spyvm.error import Exit

    print s_frame.print_stack()
    if not we_are_translated():
        import pdb; pdb.set_trace()
    else:
        print s_frame
        pid = os.getpid()
        gdbpid = fork()
        if gdbpid == 0:
            shell = os.environ.get("SHELL") or os.environ.get("COMSPEC") or "/bin/sh"
            sepidx = shell.rfind(os.sep) + 1
            if sepidx > 0:
                argv0 = shell[sepidx:]
            else:
                argv0 = shell
            try:
                os.execv(shell, [argv0, "-c", "gdb -p %d" % pid])
            except OSError as e:
                raise Exit('Could not start GDB: %s.' % e)
        # raise Exit('Halt is not well defined when translated.')
    return w_rcvr

@DebuggingPlugin.expose_primitive(unwrap_spec=[object])
def isRSqueak(interp, s_frame, w_rcvr):
    return interp.space.w_true

@DebuggingPlugin.expose_primitive(unwrap_spec=[object])
def isVMTranslated(interp, s_frame, w_rcvr):
    from rpython.rlib.objectmodel import we_are_translated
    if we_are_translated():
        return interp.space.w_true
    else:
        return interp.space.w_false

@DebuggingPlugin.expose_primitive(unwrap_spec=[object, object])
def debugPrint(interp, s_frame, w_rcvr, w_string):
    if not isinstance(w_string, model.W_BytesObject):
        raise error.PrimitiveFailedError()
    print interp.space.unwrap_string(w_string).replace('\r', '\n')
    return w_rcvr

@DebuggingPlugin.expose_primitive(unwrap_spec=[object])
def stopUIProcess(interp, s_frame, w_rcvr):
    if DebuggingPlugin.userdata.get('stop_ui', False):
        return interp.space.w_true
    else:
        return interp.space.w_false
