pub const c = @cImport({
    @cInclude("JanRenderer/VolkUsage.h");
    @cInclude("JanRenderer/VmaUsage.h");
    @cDefine("CGLM_FORCE_DEPTH_ZERO_TO_ONE", "");
    @cInclude("cglm/struct.h");
});

pub const JrCamera = @import("JrCamera.zig");

pub const JrGlfwUserPointer = extern struct {
    camera: ?*JrCamera,
    renderer: ?*anyopaque,
};
