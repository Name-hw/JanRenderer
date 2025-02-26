const builtin = @import("builtin");
const std = @import("std");
const fs = std.fs;
const fmt = std.fmt;
const mem = std.mem;

const CSourceFiles: []const []const u8 =
    &.{"src/JanRenderer/JanRenderer.cpp"};
const CFlags: []const []const u8 = &.{"-std=c++17"};

fn findCSourceFiles(b: *std.Build, absoluteDir: std.fs.Dir) ![]const []const u8 {
    var dir_walker = try absoluteDir.walk(b.allocator);
    defer dir_walker.deinit();

    var src_files_arrayList = std.ArrayList([]const u8).init(b.allocator);
    while (try dir_walker.next()) |entry| {
        if (entry.kind == .file) {
            const path =
                try std.mem.replaceOwned(u8, b.allocator, entry.path, "\\", "/");
            try src_files_arrayList.append(path);
        }
    }

    return src_files_arrayList.items;
}

fn addPkg_C(b: *std.Build, pkg_name: []const u8, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !*std.Build.Step.Compile {
    const cwd = fs.cwd();

    // pkg_dep
    const pkg_dep = b.dependency(pkg_name, .{});
    const pkg_dir = pkg_dep.path("");
    const pkg_dir_include = pkg_dir.path(b, "include");
    const pkg_dir_src = pkg_dir.path(b, "src");

    var absoluteDir = try cwd.openDir(pkg_dir.getPath(b), .{});
    defer absoluteDir.close();

    std.log.debug("{s}", .{try absoluteDir.realpathAlloc(b.allocator, "")});

    var absoluteDir_src = try absoluteDir.openDir("src", .{ .iterate = true });
    defer absoluteDir_src.close();

    // pkg_lib
    const pkg_lib = b.addSharedLibrary(.{
        .name = pkg_name,
        .target = target,
        .optimize = optimize,
    });
    pkg_lib.linkLibC();
    pkg_lib.addIncludePath(pkg_dir_include);
    pkg_lib.installHeadersDirectory(pkg_dir_include, "", .{});

    const src_files = try findCSourceFiles(b, absoluteDir_src);

    pkg_lib.addCSourceFiles(.{ .root = pkg_dir_src, .files = src_files, .flags = &.{"-std=c99"} });

    // installArtifact
    b.installArtifact(pkg_lib);

    return pkg_lib;
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to
    // select between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we
    // do not set a preferred release mode, allowing the user to decide how to
    // optimize.
    const optimize = b.standardOptimizeOption(.{});

    // const optimize_pkg = .ReleaseFast;

    // cglm_lib
    // const cglm_lib = try addPkg_C(b, "cglm", target, optimize_pkg);

    // JrClasses_lib
    const JrClasses_lib = b.addStaticLibrary(.{
        .name = "JrClasses",
        .root_source_file = b.path("src/JanRenderer/JrClasses/JrCamera.zig"),
        .target = target,
        .optimize = optimize,
    });
    // JrClasses_lib C source
    JrClasses_lib.linkLibC();
    // JrClasses_lib vcpkg library
    JrClasses_lib.addIncludePath(b.path("vcpkg_installed/x64-windows/include/"));
    JrClasses_lib.addLibraryPath(b.path("vcpkg_installed/x64-windows/lib/"));

    // JrClasses.h (unused)
    // There are many bugs in zig, so use JrClasses.hpp that I created instead of
    // this automatically generated header file.
    //_ = JrClasses_lib.getEmittedH();
    // JrClasses_lib.installHeader(b.path(".zig-cache/JrClasses.h"),
    // "JrClasses.h");

    b.installArtifact(JrClasses_lib);

    // JanRenderer_lib
    const JanRenderer_lib = b.addStaticLibrary(.{
        .name = "JanRenderer",
        .target = target,
        .optimize = optimize,
    });
    // JanRenderer_lib C source
    JanRenderer_lib.linkLibCpp();
    JanRenderer_lib.linkLibrary(JrClasses_lib);
    JanRenderer_lib.addIncludePath(b.path("src/JanRenderer/"));
    JanRenderer_lib.addIncludePath(b.path("include/"));
    JanRenderer_lib.addCSourceFiles(.{ .root = b.path(""), .files = CSourceFiles, .flags = CFlags });
    // JanRenderer_lib vcpkg library
    JanRenderer_lib.addIncludePath(b.path("vcpkg_installed/x64-windows/include/"));
    JanRenderer_lib.addLibraryPath(b.path("vcpkg_installed/x64-windows/lib/"));
    JanRenderer_lib.linkSystemLibrary("glfw3dll");

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(JanRenderer_lib);
    const JanRenderer_lib_install_artifact = b.addInstallArtifact(JanRenderer_lib, .{ .dest_dir = .{ .override = .{ .custom = "../bin" } } });
    b.getInstallStep().dependOn(&JanRenderer_lib_install_artifact.step);

    // TestApp
    const TestApp_exe = b.addExecutable(.{
        .name = "TestApp",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/TestApp/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    TestApp_exe.addIncludePath(b.path("include/"));
    TestApp_exe.addLibraryPath(b.path("vcpkg_installed/x64-windows/lib/"));
    TestApp_exe.linkSystemLibrary("glfw3dll");
    TestApp_exe.linkLibrary(JanRenderer_lib);

    b.installArtifact(TestApp_exe);
    const exe_install_artifact = b.addInstallArtifact(TestApp_exe, .{ .dest_dir = .{ .override = .{ .custom = "../bin" } } });
    b.getInstallStep().dependOn(&exe_install_artifact.step);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(TestApp_exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache
    // directory. This is not necessary, however, if the application depends on
    // other installed files, this ensures they will be present and in the
    // expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help`
    // menu, and can be selected like this: `zig build run` This will evaluate the
    // `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.

    // const exe_unit_tests = b.addTest(.{
    //     .root_source_file = b.path("src/TestApp/main.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    //// Similar to creating the run step earlier, this exposes a `test` step to
    //// the `zig build --help` menu, providing a way for the user to request
    //// running the unit tests.
    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_exe_unit_tests.step);
}
