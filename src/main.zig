const std = @import("std");
const string = []const u8;
const builtin = @import("builtin");
pub const build_options = @import("build_options");
const zigmod = @import("zigmod");
const win32 = @import("win32");

//
//

pub fn main() !void {
    const gpa = std.heap.c_allocator;

    const proc_args = try std.process.argsAlloc(gpa);
    const args = proc_args[1..];
    const self_path = try std.fs.selfExePathAlloc(gpa);

    if (args.len == 0) {
        std.debug.print("zigmod {s} {s} {s} {s}\n", .{
            build_options.version,
            @tagName(builtin.os.tag),
            @tagName(builtin.cpu.arch),
            @tagName(builtin.abi),
        });
        std.debug.print("\n", .{});
        std.debug.print("The commands available are:\n", .{});
        inline for (comptime std.meta.declarations(zigmod.commands)) |decl| {
            std.debug.print("  - {s}\n", .{decl.name});
        }
        return;
    }

    if (builtin.os.tag == .windows) {
        const console = win32.system.console;
        const h_out = console.GetStdHandle(console.STD_OUTPUT_HANDLE);
        _ = console.SetConsoleMode(h_out, console.CONSOLE_MODE{
            .ENABLE_PROCESSED_INPUT = 1, //ENABLE_PROCESSED_OUTPUT
            .ENABLE_LINE_INPUT = 1, //ENABLE_WRAP_AT_EOL_OUTPUT
            .ENABLE_ECHO_INPUT = 1, //ENABLE_VIRTUAL_TERMINAL_PROCESSING
        });
    }

    try zigmod.init();
    defer zigmod.deinit();

    inline for (comptime std.meta.declarations(zigmod.commands)) |decl| {
        if (std.mem.eql(u8, args[0], decl.name)) {
            const cmd = @field(zigmod.commands, decl.name);
            try cmd.execute(self_path, args[1..]);
            return;
        }
    }

    var sub_cmd_args = std.ArrayList(string).init(gpa);
    try sub_cmd_args.append(try std.fmt.allocPrint(gpa, "zigmod-{s}", .{args[0]}));
    for (args[1..]) |item| {
        try sub_cmd_args.append(item);
    }
    const result = std.process.Child.run(.{ .allocator = gpa, .argv = sub_cmd_args.items }) catch |e| switch (e) {
        else => |ee| return ee,
        error.FileNotFound => {
            fail("unknown command \"{s}\" for \"zigmod\"", .{args[0]});
        },
    };
    try std.io.getStdOut().writeAll(result.stdout);
    try std.io.getStdErr().writeAll(result.stderr);
}

//
//

const ansi_red = "\x1B[31m";
const ansi_reset = "\x1B[39m";

pub fn assert(ok: bool, comptime fmt: string, args: anytype) void {
    if (!ok) {
        std.debug.print(ansi_red ++ fmt ++ ansi_reset ++ "\n", args);
        std.process.exit(1);
    }
}

pub fn fail(comptime fmt: string, args: anytype) noreturn {
    assert(false, fmt, args);
    unreachable;
}
