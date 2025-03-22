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

// WIP
pub export fn jrCamera_new() callconv(.C) *JrCamera {
    const allocator = std.heap.c_allocator;
    const newJrCamera = allocator.create(JrCamera) catch unreachable;

    newJrCamera.* = JrCamera{};

    return newJrCamera;
}
