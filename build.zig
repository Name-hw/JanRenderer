const builtin = @import("builtin");
const std = @import("std");
const fs = std.fs;
const fmt = std.fmt;
const mem = std.mem;
const ArrayList = std.ArrayList;

const CSourceFiles: []const []const u8 =
    &.{ "JanRenderer.cpp", "VolkUsage.cpp" };
const CFlags: []const []const u8 = &.{"-std=c++17"};

const ZigLibs = struct {
    zmath: *std.Build.Module,
    zglfw: *std.Build.Module,
    zgui: *std.Build.Module,
};

fn absolutePathToRelative(b: *std.Build, path: []const u8) ![]u8 {
    return try mem.replaceOwned(u8, b.allocator, path, "\\", "/");
}

fn findCSourceFiles(b: *std.Build, absoluteDir: std.fs.Dir, fileNames: ?[]const []const u8) ![]const []const u8 {
    var dir_walker = try absoluteDir.walk(b.allocator);
    defer dir_walker.deinit();

    var src_files_arrayList = std.ArrayList([]const u8).init(b.allocator);

    if (fileNames) |fileNames_| {
        while (try dir_walker.next()) |entry| {
            for (fileNames_) |fileName| {
                if (mem.eql(u8, entry.basename, fileName)) {
                    const path = try absolutePathToRelative(b, entry.path);

                    try src_files_arrayList.append(path);
                }
            }
        }
    } else {
        while (try dir_walker.next()) |entry| {
            if (entry.kind == .file and mem.endsWith(u8, entry.basename, "c") and mem.endsWith(u8, entry.basename, "h")) {
                const path = try absolutePathToRelative(b, entry.path);

                try src_files_arrayList.append(path);
            }
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

fn buildJrObjects(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, step: *std.Build.Step, libs: *const ZigLibs) !ArrayList(*std.Build.Step.Compile) {
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

    var JrObject_libs = std.ArrayList(*std.Build.Step.Compile).init(b.allocator);

    for (JrObject_fileNames) |JrObject_fileName| {
        const JrObject_path = src_JrObjects_path.path(b, JrObject_fileName);

        const JrObject_lib = b.addStaticLibrary(.{
            .name = try removeFileExtension(JrObject_fileName),
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
        JrObject_lib.root_module.addImport("zmath", libs.zmath);
        JrObject_lib.root_module.addImport("zglfw", libs.zglfw);
        JrObject_lib.root_module.addImport("zgui", libs.zgui);

        // JrObjects.h (unused)
        // There are many bugs in zig, so use JrObjects.hpp that I created instead of
        // this automatically generated header file.
        //const JrObject_lib_header = JrObject_lib.getEmittedH();
        //JrObject_lib.installHeader(JrObject_lib_header, "");

        const JrObject_lib_installArtifact = b.addInstallArtifact(JrObject_lib, .{});
        //JrObject_lib_installArtifact.emitted_h = JrObject_lib_header.;
        step.dependOn(&JrObject_lib_installArtifact.step);

        try JrObject_libs.append(JrObject_lib);
    }

    return JrObject_libs;
}

pub fn linkJrObjects(lib: *std.Build.Step.Compile, JrObject_libs: ArrayList(*std.Build.Step.Compile)) !void {
    for (JrObject_libs.items) |JrObject_lib| {
        lib.linkLibrary(JrObject_lib);
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

    // zmath
    const zmath = b.dependency("zmath", .{});
    const zmath_module = zmath.module("root");

    // zglfw
    const zglfw = b.dependency("zglfw", .{});
    const zglfw_module = zglfw.module("root");
    const zglfw_lib = zglfw.artifact("glfw");

    // zgui
    const zgui = b.dependency("zgui", .{
        .backend = .glfw_vulkan,
    });
    const zgui_module = zgui.module("root");
    const zgui_lib = zgui.artifact("imgui");
    zgui_lib.root_module.addCMacro("IMGUI_IMPL_VULKAN_USE_VOLK", "");
    zgui_lib.addIncludePath(b.path("vcpkg_installed/x64-windows/include/")); // to include vulkan

    //const installArtifacts = [2]*std.Build.Step.InstallArtifact{
    //    b.addInstallArtifact(zglfw_lib, .{}),
    //    b.addInstallArtifact(zgui_lib, .{}),
    //};

    // JanRenderer.lib step
    const lib_step = b.step("lib", "Run the library build step");
    lib_step.dependOn(&zglfw_lib.step);
    lib_step.dependOn(&zgui_lib.step);

    const JrObject_libs = buildJrObjects(b, target, optimize, lib_step, &.{
        .zmath = zmath_module,
        .zglfw = zglfw_module,
        .zgui = zgui_module,
    }) catch |err| {
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
    JanRenderer_lib.addIncludePath(b.path("include/"));
    JanRenderer_lib.addCSourceFiles(.{ .root = b.path("src/JanRenderer/"), .files = CSourceFiles, .flags = CFlags });
    // JanRenderer_lib vcpkg library
    JanRenderer_lib.addIncludePath(b.path("vcpkg_installed/x64-windows/include/"));
    JanRenderer_lib.addLibraryPath(b.path("vcpkg_installed/x64-windows/lib/"));
    JanRenderer_lib.installHeadersDirectory(b.path("vcpkg_installed/x64-windows/include/cglm/"), "cglm", .{});
    // JanRenderer_lib zig library
    JanRenderer_lib.linkLibrary(zglfw_lib);
    JanRenderer_lib.linkLibrary(zgui_lib);
    JanRenderer_lib.addIncludePath(zgui.path("libs/imgui"));

    linkJrObjects(JanRenderer_lib, JrObject_libs) catch |err| {
        std.debug.print("Failed to link JrObjects with JanRenderer! ({})\n", .{err});
        return err;
    };

    const lib_installArtifact = b.addInstallArtifact(JanRenderer_lib, .{});

    lib_step.dependOn(&lib_installArtifact.step);

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
    TestApp_exe.linkLibCpp();
    // TestApp_exe zig library
    TestApp_exe.addIncludePath(b.path("zig-out/include/"));
    TestApp_exe.addLibraryPath(b.path("zig-out/lib/"));
    TestApp_exe.linkLibrary(JanRenderer_lib);

    const exe_installArtifact = b.addInstallArtifact(TestApp_exe, .{});

    const exe_step = b.step("exe", "Run the executable build step");
    exe_step.dependOn(&zglfw_lib.step);
    exe_step.dependOn(&zgui_lib.step);
    exe_step.dependOn(&exe_installArtifact.step);

    b.getInstallStep().dependOn(lib_step);
    b.getInstallStep().dependOn(exe_step);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(TestApp_exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache
    // directory. This is not necessary, however, if the application depends on
    // other installed files, this ensures they will be present and in the
    // expected location.
    run_cmd.step.dependOn(lib_step);
    run_cmd.step.dependOn(exe_step);

    // The run command is executed inside zig-out/bin/
    run_cmd.setCwd(b.path("zig-out/bin/"));

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
