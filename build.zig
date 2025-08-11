const std = @import("std");
const string = []const u8;
const builtin = @import("builtin");
const deps = @import("./deps.zig");

pub fn build(b: *std.Build) void {
    b.reference_trace = 256;

    const target = b.standardTargetOptions(.{});
    const mode = b.option(std.builtin.Mode, "mode", "") orelse .Debug;
    const use_full_name = b.option(bool, "use-full-name", "") orelse false;
    const with_arch_os = b.fmt("-{s}-{s}", .{ @tagName(target.result.cpu.arch), @tagName(target.result.os.tag) });
    const exe_name = b.fmt("{s}{s}", .{ "zigmod", if (use_full_name) with_arch_os else "" });
    const exe = b.addExecutable(.{
        .name = exe_name,
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = mode,
    });
    const tag = b.option(string, "tag", "");
    const strip = b.option(bool, "strip", "Build without debug info.") orelse false;
    const disable_llvm = b.option(bool, "disable_llvm", "use the non-llvm zig codegen") orelse false;
    _ = &disable_llvm; // macos can't mix the flags rn because it needs llvm but also can't use lld

    const exe_options = b.addOptions();
    exe.root_module.addImport("build_options", exe_options.createModule());
    exe_options.addOption(string, "version", tag orelse std.mem.trimRight(u8, b.run(&.{ "git", "describe", "--tags" }), "\n"));

    deps.addAllTo(exe);
    exe.root_module.strip = strip;
    // exe.use_llvm = !disable_llvm;
    // exe.use_lld = !disable_llvm;
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    //

    const test_step = b.step("test", "Stub for ziginfra");
    test_step.dependOn(&exe.step);
}
