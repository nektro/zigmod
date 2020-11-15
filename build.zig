const std = @import("std");
const Builder = std.build.Builder;
const builtin = @import("builtin");

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});

    b.setPreferredReleaseMode(.ReleaseSafe);
    const mode = b.standardReleaseOptions();

    const use_full_name = b.option(bool, "use-full-name", "") orelse false;
    const with_os_arch = b.fmt("-{}-{}", .{@tagName(target.os_tag orelse builtin.os.tag), @tagName(target.cpu_arch orelse builtin.arch)});
    const version_tag = if (b.option([]const u8, "tag", "")) |vt| b.fmt("-{}", .{vt}) else "";
    const exe_name = b.fmt("{}{}{}", .{ "zigmod-zig", version_tag, if (use_full_name) with_os_arch else "" });

    const exe = b.addExecutable(exe_name, "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.strip = true;

    exe.linkLibC();

    exe.addIncludeDir("./libs/yaml/include");
    exe.addCSourceFile("./libs/yaml/src/api.c", &[_][]const u8{
        // taken from https://github.com/yaml/libyaml/blob/0.2.5/CMakeLists.txt#L5-L8
        "-DYAML_VERSION_MAJOR=0",
        "-DYAML_VERSION_MINOR=2",
        "-DYAML_VERSION_PATCH=5",
        "-DYAML_VERSION_STRING=\"0.2.5\"",
    });
    exe.addCSourceFile("./libs/yaml/src/dumper.c", &[_][]const u8{});
    exe.addCSourceFile("./libs/yaml/src/emitter.c", &[_][]const u8{});
    exe.addCSourceFile("./libs/yaml/src/loader.c", &[_][]const u8{});
    exe.addCSourceFile("./libs/yaml/src/parser.c", &[_][]const u8{});
    exe.addCSourceFile("./libs/yaml/src/reader.c", &[_][]const u8{});
    exe.addCSourceFile("./libs/yaml/src/scanner.c", &[_][]const u8{});
    exe.addCSourceFile("./libs/yaml/src/writer.c", &[_][]const u8{});

    exe.addPackagePath("known-folders", "./libs/zig-known-folders/known-folders.zig");

    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
