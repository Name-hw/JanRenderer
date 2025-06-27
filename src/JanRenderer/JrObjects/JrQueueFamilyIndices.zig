const std = @import("std");
const volk = @cImport({
    @cInclude("volk.h");
});
const cglm = @cImport({
    @cDefine("CGLM_FORCE_DEPTH_ZERO_TO_ONE", "");
    @cInclude("cglm/struct.h");
});

const Self = @This();

graphics_family: ?u32,
present_family: ?u32,
transfer_family: ?u32,
compute_family: ?u32,

pub export fn jrQueueFamilyIndices_isComplete(self: *Self) callconv(.C) bool {
    return self.graphics_family != null and self.present_family != null and self.transfer_family != null and self.compute_family != null;
}
