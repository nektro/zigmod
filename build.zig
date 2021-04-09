const std = @import("std");
const Builder = std.build.Builder;
const builtin = std.builtin;
const deps = @import("./deps.zig");

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});

    b.setPreferredReleaseMode(.ReleaseSafe);
    const mode = b.standardReleaseOptions();

    const use_full_name = b.option(bool, "use-full-name", "") orelse false;
    const with_arch_os = b.fmt("-{s}-{s}", .{@tagName(target.cpu_arch orelse builtin.arch), @tagName(target.os_tag orelse builtin.os.tag)});
    const exe_name = b.fmt("{s}{s}", .{ "zigmod", if (use_full_name) with_arch_os else "" });

    const exe = b.addExecutable(exe_name, "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addBuildOption([]const u8, "version", b.option([]const u8, "tag", "") orelse "dev");
    const bootstrap = b.option(bool, "bootstrap", "bootstrapping with just the zig compiler");
    exe.addBuildOption(bool, "bootstrap", bootstrap != null);

    if (bootstrap != null) {
        exe.linkLibC();

        exe.addIncludeDir("./libs/yaml/include");
        exe.addCSourceFile("./libs/yaml/src/api.c", &.{
            // taken from https://github.com/yaml/libyaml/blob/0.2.5/CMakeLists.txt#L5-L8
            "-DYAML_VERSION_MAJOR=0",
            "-DYAML_VERSION_MINOR=2",
            "-DYAML_VERSION_PATCH=5",
            "-DYAML_VERSION_STRING=\"0.2.5\"",
            "-DYAML_DECLARE_STATIC=1",
        });
        exe.addCSourceFile("./libs/yaml/src/dumper.c", &.{});
        exe.addCSourceFile("./libs/yaml/src/emitter.c", &.{});
        exe.addCSourceFile("./libs/yaml/src/loader.c", &.{});
        exe.addCSourceFile("./libs/yaml/src/parser.c", &.{});
        exe.addCSourceFile("./libs/yaml/src/reader.c", &.{});
        exe.addCSourceFile("./libs/yaml/src/scanner.c", &.{});
        exe.addCSourceFile("./libs/yaml/src/writer.c", &.{});

        exe.addPackagePath("zigmod", "./src/lib.zig");
        exe.addPackagePath("ansi", "./libs/zig-ansi/src/lib.zig");
    }
    else {
        deps.addAllTo(exe);
    }

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
