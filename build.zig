const std = @import("std");
const string = []const u8;
const builtin = @import("builtin");
const deps = @import("./deps.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.option(std.builtin.Mode, "mode", "");
    const optimize = b.standardOptimizeOption(.{});
    const optimization_mode = mode orelse optimize;
    const use_full_name = b.option(bool, "use-full-name", "") orelse false;
    const with_arch_os = b.fmt("-{s}-{s}", .{ @tagName(target.result.cpu.arch), @tagName(target.result.os.tag) });
    const exe_name = b.fmt("{s}{s}", .{ "zigmod", if (use_full_name) with_arch_os else "" });
    const exe = b.addExecutable(.{
        .name = exe_name,
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimization_mode,
    });
    const tag = b.option(string, "tag", "") orelse "dev";
    const strip = b.option(bool, "strip", "Build without debug info.") orelse false;

    const exe_options = b.addOptions();
    exe.root_module.addImport("build_options", exe_options.createModule());
    exe_options.addOption(string, "version", tag);

    deps.addAllTo(exe);
    exe.root_module.strip = strip;
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
