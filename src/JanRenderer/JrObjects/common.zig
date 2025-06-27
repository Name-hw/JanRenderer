const std = @import("std");
const volk = @cImport({
    @cInclude("volk.h");
});
const cglm = @cImport({
    @cDefine("CGLM_FORCE_DEPTH_ZERO_TO_ONE", "");
    @cInclude("cglm/struct.h");
});

pub const JrCamera = @import("JrCamera.zig");
pub const JrShader = @import("JrShader.zig");

pub const JrGlfwUserPointer = extern struct {
    camera: ?*JrCamera.JrCamera,
    renderer: ?*anyopaque,
};
