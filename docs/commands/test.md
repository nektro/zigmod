## `test` command

```
zigmod test
```

Use this command to easily run your Zigmod-enabled module tests in a debugger.
`zig build test` is designed as a task runner and so it does not do the full-process replacement necessary for debuggers like GDB and LLDB to follow when an error occurs.

Below is an example of the UX you can get using my https://github.com/nektro/zig-whatwg-url package in a simulated example.

```
$ gdb --args zigmod test
GNU gdb (GDB) 16.3
Copyright (C) 2024 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Type "show copying" and "show warranty" for details.
This GDB was configured as "x86_64-unknown-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<https://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
    <http://www.gnu.org/software/gdb/documentation/>.

For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from zigmod...
(gdb) r
Starting program: /home/me/dev/zigmod/zig-out/bin/zigmod test
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/nix/store/km4g87jxsqxvcq344ncyb8h1i6f3cqxh-glibc-2.40-218/lib/libthread_db.so.1".
process 1570642 is executing new program: /home/me/.local/share/zig/0.16.0/zig
[Detaching after fork from child process 1570645]
[New LWP 1570646]
[LWP 1570646 exited]
process 1570642 is executing new program: /home/me/zig-cache/o/82896c6cdefce8104394f5e8ce6a5138/test
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/nix/store/km4g87jxsqxvcq344ncyb8h1i6f3cqxh-glibc-2.40-218/lib/libthread_db.so.1".
thread 1570642 panic: reached unreachable code
/home/me/dev/zig-whatwg-url/url.zig:372:25: 0x1294c44 in parseBasic (url.zig)
                        unreachable;
                        ^
/home/me/dev/zig-whatwg-url/url.zig:42:26: 0x1274b1e in parse (url.zig)
        return parseBasic(alloc, input, null, null);
                         ^
/home/me/dev/zig-whatwg-url/test.zig:15:32: 0x1275c61 in test_2 (test.zig)
    const u = try url.URL.parse(allocator, "https://en.wikipedia.org/w/index.php?title=URL", null);
                               ^
/home/me/.local/share/zig/0.16.0/lib/compiler/test_runner.zig:291:25: 0x122fde6 in mainTerminal (test_runner.zig)
        if (test_fn.func()) |_| {
                        ^
/home/me/.local/share/zig/0.16.0/lib/compiler/test_runner.zig:73:28: 0x122f1e2 in main (test_runner.zig)
        return mainTerminal(init);
                           ^
/home/me/.local/share/zig/0.16.0/lib/std/start.zig:699:88: 0x122be0c in callMain (std.zig)
    if (fn_info.params[0].type.? == std.process.Init.Minimal) return wrapMain(root.main(.{
                                                                                       ^
/home/me/.local/share/zig/0.16.0/lib/std/start.zig:638:20: 0x122bbe6 in callMainWithArgs (std.zig)
    return callMain(argv[0..argc], env_block);
                   ^
???:?:?: 0x7ffff7c2a4d7 in __libc_start_call_main (/nix/store/km4g87jxsqxvcq344ncyb8h1i6f3cqxh-glibc-2.40-218/lib/libc.so.6)
???:?:?: 0x7ffff7c2a59a in __libc_start_main_alias_2 (/nix/store/km4g87jxsqxvcq344ncyb8h1i6f3cqxh-glibc-2.40-218/lib/libc.so.6)
/home/me/.local/share/zig/0.16.0/lib/libc/glibc/sysdeps/x86_64/start.S:115: 0x164b0f0 in ??? (/home/me/.local/share/zig/0.16.0/lib/libc/glibc/sysdeps/x86_64/start.S)
        call *__libc_start_main@GOTPCREL(%rip)


Thread 1 "test" received signal SIGABRT, Aborted.
__pthread_kill_implementation (threadid=<optimized out>, signo=signo@entry=6, no_tid=no_tid@entry=0) at pthread_kill.c:44
warning: 44     pthread_kill.c: No such file or directory
(gdb) bt
#0  __pthread_kill_implementation (threadid=<optimized out>, signo=signo@entry=6, no_tid=no_tid@entry=0) at pthread_kill.c:44
#1  0x00007ffff7c9cb13 in __pthread_kill_internal (threadid=<optimized out>, signo=6) at pthread_kill.c:78
#2  0x00007ffff7c4190e in __GI_raise (sig=sig@entry=6) at ../sysdeps/posix/raise.c:26
#3  0x00007ffff7c28942 in __GI_abort () at abort.c:79
#4  0x00000000010857c3 in process.abort ()
#5  0x0000000001085481 in debug.defaultPanic (msg=..., first_trace_addr=...)
#6  0x000000000108bb44 in debug.FullPanic((function 'defaultPanic')).reachedUnreachable ()
#7  0x0000000001294c45 in url.URL.parseBasic (alloc=..., input=..., base=..., state_override=...)
#8  0x0000000001274b1f in url.URL.parse (alloc=..., input=..., base=...) at url.zig:42
#9  0x0000000001275c62 in test.test_2 () at test.zig:15
#10 0x000000000122fde7 in test_runner.mainTerminal (init=...)
#11 0x000000000122f1e3 in test_runner.main (init=...)
#12 0x000000000122be0d in start.callMain (args=..., environ=...)
#13 0x000000000122bbe7 in start.main (c_argc=2, c_argv=0x7fffffffc408, c_envp=0x7fffffffc420)
```

You can also use this with GUI debuggers such as [VS Code](https://code.visualstudio.com/docs/debugtest/debugging-configuration) and [Zed](https://zed.dev/docs/debugger).
