const Self = @This();

graphics_family: ?u32,
present_family: ?u32,
transfer_family: ?u32,
compute_family: ?u32,

pub fn isComplete(self: *Self) bool {
    return self.graphics_family != null and self.present_family != null and self.transfer_family != null and self.compute_family != null;
}
