const std = @import("std");
const cglm = @cImport({
    @cDefine("CGLM_FORCE_DEPTH_ZERO_TO_ONE", "");
    @cInclude("cglm/struct.h");
});
const glfw = @cImport({
    @cDefine("VK_USE_PLATFORM_WIN32_KHR", "");
    @cDefine("GLFW_INCLUDE_VULKAN", "");
    @cInclude("GLFW/glfw3.h");
});

pub const JrCamera = @import("JrCamera.zig");
pub const JrShader = @import("JrShader.zig");
pub const JrGui = @import("JrGui.zig");

// WIP
pub export fn jrCamera_new() callconv(.C) *JrCamera {
    const allocator = std.heap.c_allocator;
    const newJrCamera = allocator.create(JrCamera) catch unreachable;

    newJrCamera.* = JrCamera{};

    return newJrCamera;
}

pub export fn jrShader_new() callconv(.C) *JrShader.JrShader {
    var whatIsItsName: JrShader.JrShader = undefined;
    return &whatIsItsName;
}

pub export fn jrGui_new() callconv(.C) *JrGui {
    const allocator = std.heap.c_allocator;
    const newJrGui = allocator.create(JrGui) catch unreachable;

    newJrGui.* = JrGui{};

    return newJrGui;
}
