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
        if (entry.kind == .file and mem.endsWith(u8, entry.basename, "c") and mem.endsWith(u8, entry.basename, "h")) {
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

    //std.log.debug("{s}", .{try absoluteDir.realpathAlloc(b.allocator, "")}); //print directory of pkg

    var absoluteDir_src = try absoluteDir.openDir("src", .{ .iterate = true });
    defer absoluteDir_src.close();

    // pkg_lib
    const pkg_lib = b.addStaticLibrary(.{
        .name = pkg_name,
        .target = target,
        .optimize = optimize,
    });
    pkg_lib.linkLibC();
    pkg_lib.addIncludePath(pkg_dir_include);
    pkg_lib.installHeadersDirectory(pkg_dir_include, "", .{});

    const src_files = try findCSourceFiles(b, absoluteDir_src);

    pkg_lib.addCSourceFiles(.{ .root = pkg_dir_src, .files = src_files, .flags = &.{"-std=c99"} });

    return pkg_lib;
}

fn findJrObjects(b: *std.Build, absoluteDir: std.fs.Dir) ![][]const u8 {
    var dir_iterator = absoluteDir.iterate();

    var JrObject_fileNameArrayList = std.ArrayList([]const u8).init(b.allocator);
    defer JrObject_fileNameArrayList.deinit();

    while (try dir_iterator.next()) |entry| {
        if (entry.kind == .file and mem.startsWith(u8, entry.name, "Jr")) {
            try JrObject_fileNameArrayList.append(try b.allocator.dupe(u8, entry.name));
        }
    }

    const JrObject_fileNames: [][]const u8 = try JrObject_fileNameArrayList.toOwnedSlice();

    return JrObject_fileNames;
}

fn removeFileExtension(fileName: []const u8) ![]const u8 {
    const dotIndex = std.mem.lastIndexOfScalar(u8, fileName, '.') orelse fileName.len;
    return fileName[0..dotIndex];
}

fn buildJrObjects(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !void {
    // library
    const zmath = b.dependency("zmath", .{});

    // current working directory
    const cwd = fs.cwd();

    // src/JanRenderer/JrObjects/
    const src_JrObjects_path = b.path("src/JanRenderer/JrObjects/");
    var src_JrObjects_dir = try cwd.openDir(src_JrObjects_path.getPath(b), .{ .iterate = true });
    defer src_JrObjects_dir.close();

    // src/JanRenderer/JrObjects/Jr*
    const JrObject_fileNames = findJrObjects(b, src_JrObjects_dir) catch |err| {
        std.debug.print("Failed to find JrObjects! ({})\n", .{err});
        return err;
    };

    for (JrObject_fileNames) |object_fileName| {
        const JrObject_path = src_JrObjects_path.path(b, object_fileName);

        const JrObject_lib = b.addStaticLibrary(.{
            .name = try removeFileExtension(object_fileName),
            .root_source_file = JrObject_path,
            .target = target,
            .optimize = optimize,
        });
        // JrObject_lib C source
        JrObject_lib.linkLibC();
        JrObject_lib.addIncludePath(b.path("include/"));
        // JrObject_lib vcpkg library
        JrObject_lib.addIncludePath(b.path("vcpkg_installed/x64-windows/include/"));
        JrObject_lib.addLibraryPath(b.path("vcpkg_installed/x64-windows/lib/"));
        // JrObject_lib zig library
        JrObject_lib.root_module.addImport("zmath", zmath.module("root"));
        //JrObject_lib.root_module.addImport("coyoteEcs", coyoteEcs.module(""));

        // JrObjects.h (unused)
        // There are many bugs in zig, so use JrObjects.hpp that I created instead of
        // this automatically generated header file.
        //const JrObject_lib_header = JrObject_lib.getEmittedH();
        //JrObject_lib.installHeader(JrObject_lib_header, "");

        b.installArtifact(JrObject_lib);
        const JrObject_lib_installArtifact = b.addInstallArtifact(JrObject_lib, .{});
        //JrObject_lib_installArtifact.emitted_h = JrObject_lib_header.;
        b.getInstallStep().dependOn(&JrObject_lib_installArtifact.step);
    }
}

fn linkJrObjects(b: *std.Build, lib: *std.Build.Step.Compile) !void {
    const cwd = fs.cwd();

    const zigOut_lib_path = b.path("zig-out/lib/");
    var zigOut_lib_dir = try cwd.openDir(zigOut_lib_path.getPath(b), .{ .iterate = true });
    defer zigOut_lib_dir.close();

    lib.addLibraryPath(zigOut_lib_path);

    // zig-out/lib/Jr*
    const JrObject_fileNames = try findJrObjects(b, zigOut_lib_dir);

    for (JrObject_fileNames) |JrObject_fileName| {
        lib.linkSystemLibrary(try removeFileExtension(JrObject_fileName));
    }
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

    //const optimize_pkg = .ReleaseFast;

    // coyote-ecs
    //const coyoteEcs = b.dependency("coyote-ecs", .{});

    // glfw
    b.installBinFile("vcpkg_installed/x64-windows/bin/glfw3.dll", "glfw3.dll");
    b.installLibFile("vcpkg_installed/x64-windows/lib/glfw3dll.lib", "glfw3dll.lib");

    buildJrObjects(b, target, optimize) catch |err| {
        std.debug.print("Failed to build JrObjects! ({})\n", .{err});
        return err;
    };

    //// JrObjects_tests
    //const JrObjects_tests = b.addTest(.{
    //    .root_source_file = b.path("src/JrObjects/JrObjects.zig"),
    //    .target = target,
    //    .optimize = optimize,
    //});
    //// JrObjects_tests C source
    //JrObjects_tests.linkLibC();
    //// JrObjects_tests vcpkg library
    //JrObjects_tests.addIncludePath(b.path("vcpkg_installed/x64-windows/include/"));
    //JrObjects_tests.addLibraryPath(b.path("vcpkg_installed/x64-windows/lib/"));
    //JrObjects_tests.linkSystemLibrary("glfw3dll");
    //// JrObjects_tests zig library
    //JrObjects_tests.root_module.addImport("zmath", zmath.module("root"));

    //const JrObjects_unit_tests = b.addRunArtifact(JrObjects_tests);
    //const test_step = b.step("test", "Run JrObjects unit tests");
    //test_step.dependOn(&JrObjects_unit_tests.step);

    // JanRenderer_lib
    const JanRenderer_lib = b.addStaticLibrary(.{
        .name = "JanRenderer",
        .target = target,
        .optimize = optimize,
    });
    // JanRenderer_lib C source
    JanRenderer_lib.linkLibCpp();
    JanRenderer_lib.addIncludePath(b.path("src/JanRenderer/"));
    JanRenderer_lib.addIncludePath(b.path("include/"));
    JanRenderer_lib.addCSourceFiles(.{ .root = b.path(""), .files = CSourceFiles, .flags = CFlags });
    // JanRenderer_lib vcpkg library
    JanRenderer_lib.addIncludePath(b.path("vcpkg_installed/x64-windows/include/"));
    JanRenderer_lib.addLibraryPath(b.path("vcpkg_installed/x64-windows/lib/"));
    JanRenderer_lib.linkSystemLibrary("glfw3dll");

    JanRenderer_lib.installHeadersDirectory(b.path("vcpkg_installed/x64-windows/include/cglm/"), "cglm", .{});

    linkJrObjects(b, JanRenderer_lib) catch |err| {
        std.debug.print("Failed to link JrObjects! ({})\n", .{err});
        return err;
    };

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(JanRenderer_lib);

    // TestApp_exe
    const TestApp_exe = b.addExecutable(.{
        .name = "TestApp",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/TestApp/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    // TestApp_exe C source
    TestApp_exe.linkLibC();
    TestApp_exe.addIncludePath(b.path("zig-out/include/"));
    TestApp_exe.addLibraryPath(b.path("zig-out/lib/"));
    TestApp_exe.linkSystemLibrary("glfw3dll");
    TestApp_exe.linkLibrary(JanRenderer_lib);

    b.installArtifact(TestApp_exe);
    const exe_installArtifact = b.addInstallArtifact(TestApp_exe, .{});
    b.getInstallStep().dependOn(&exe_installArtifact.step);

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
