const std = @import("std");
const gpa = std.heap.c_allocator;

const known_folders = @import("known-folders");
const u = @import("./util/index.zig");

//
//

pub fn execute(args: [][]u8) !void {
    //
    const home = try known_folders.getPath(gpa, .home);
    const dir = try std.fmt.allocPrint(gpa, "{}{}", .{home, "/.cache/zigmod/deps"});

    const top_module = try fetch_deps(dir, "./zig.mod");

    //
    const f = try std.fs.cwd().createFile("./deps.zig", .{});
    defer f.close();

    const w = f.writer();
    try w.print("const std = @import(\"std\");\n", .{});
    try w.print("const build = std.build;\n", .{});
    try w.print("\n", .{});
    try w.print("const home = \"{}\";\n", .{home});
    try w.print("const cache = home ++ \"/.cache/zigmod/deps\";\n", .{});
    try w.print("\n", .{});
    try w.print("{}\n", .{
        \\pub fn addAllTo(exe: *build.LibExeObjStep) void {
        \\    for (packages) |pkg| {
        \\        exe.addPackage(pkg);
        \\    }
        \\    for (c_inlude_dirs) |dir| {
        \\        exe.addIncludeDir(dir);
        \\    }
        \\    for (c_source_files) |fpath| {
        \\        exe.addCSourceFile(fpath, &[_][]const u8{});
        \\    }
        \\}
    });
    try w.print("\n", .{});
    try w.print("pub const packages = ", .{});
    try print_deps(w, dir, top_module, 0);
    try w.print(";\n", .{});
    try w.print("\n", .{});
    try w.print("{}\n", .{"pub const c_inlude_dirs = &[_][]const u8{"});
    try print_incl_dirs_to(w, top_module);
    try w.print("{};\n", .{"}"});
    try w.print("\n", .{});
    try w.print("{}\n", .{"pub const c_source_files = &[_][]const u8{"});
    try print_csrc_dirs_to(w, top_module);
    try w.print("{};\n", .{"}"});
}

fn fetch_deps(dir: []const u8, mpath: []const u8) anyerror!u.Module {
    const m = try u.ModFile.init(gpa, mpath);
    const moduledeps = &std.ArrayList(u.Module).init(gpa);
    for (m.deps) |d| {
        const p = try std.fmt.allocPrint(gpa, "{}{}{}", .{dir, "/", try d.clean_path()});
        switch (d.type) {
            .git => {
                u.print("fetch: {}: {}: {}", .{m.name, @tagName(d.type), d.path});
                if (!try u.does_file_exist(p)) {
                    try run_cmd(null, &[_][]const u8{"git", "clone", d.path, p});
                }
                else {
                    try run_cmd(p, &[_][]const u8{"git", "fetch"});
                    try run_cmd(p, &[_][]const u8{"git", "pull"});
                }
            },
        }
        switch (d.type) {
            else => {
                var dd = try fetch_deps(dir, try std.fmt.allocPrint(gpa, "{}{}", .{p, "/zig.mod"}));
                dd.clean_path = try d.clean_path();
                try moduledeps.append(dd);
            },
        }
    }
    return u.Module{
        .name = m.name,
        .main = m.main,
        .c_include_dirs = m.c_include_dirs,
        .c_source_files = m.c_source_files,
        .deps = moduledeps.items,
        .clean_path = "",
    };
}

fn run_cmd(dir: ?[]const u8, args: []const []const u8) !void {
    _ = std.ChildProcess.exec(.{ .allocator = gpa, .cwd = dir, .argv = args, }) catch |e| switch(e) {
        error.FileNotFound => {
            u.assert(false, "\"{}\" command not found", .{args[0]});
        },
        else => return e,
    };
}

fn print_deps(w: std.fs.File.Writer, dir: []const u8, m: u.Module, tabs: i32) anyerror!void {
    if (m.deps.len == 0 and tabs > 0) {
        try w.print("null", .{});
        return;
    }
    try u.print_all(w, .{"&[_]build.Pkg{"}, true);
    const t = "    ";
    const r = try u.repeat(t, tabs);
    for (m.deps) |d| {
        try w.print("{}\n", .{try u.concat(&[_][]const u8{r,t,"build.Pkg{"})});
        try w.print("{}\n", .{try u.concat(&[_][]const u8{r,t,t,".name = \"",d.name,"\","})});
        try w.print("{}\n", .{try u.concat(&[_][]const u8{r,t,t,".path = cache ++ \"/",d.clean_path,"/",d.main,"\","})});
        try w.print("{}", .{try u.concat(&[_][]const u8{r,t,t,".dependencies = "})});
        try print_deps(w, dir, d, tabs+2);
        try w.print("{}\n", .{","});
        try w.print("{}\n", .{try u.concat(&[_][]const u8{r,t,"},"})});
    }
    try w.print("{}", .{try u.concat(&[_][]const u8{r,"}"})});
}

fn print_incl_dirs_to(w: std.fs.File.Writer, mod: u.Module) anyerror!void {
    for (mod.c_include_dirs) |it| {
        try w.print("    cache ++ \"/{}/{}\",\n", .{mod.clean_path, it});
    }
    for (mod.deps) |d| {
        try print_incl_dirs_to(w, d);
    }
}

fn print_csrc_dirs_to(w: std.fs.File.Writer, mod: u.Module) anyerror!void {
    for (mod.c_source_files) |it| {
        try w.print("    cache ++ \"/{}/{}\",\n", .{mod.clean_path, it});
    }
    for (mod.deps) |d| {
        try print_csrc_dirs_to(w, d);
    }
}
