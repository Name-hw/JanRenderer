const std = @import("std");

pub const JanRenderer = extern struct {
    applicationName: [*:0]u8,
    width: c_int,
    height: c_int,
};

//pub const janRenderer_new = *const fn (applicationName: [*:0]const u8, width: c_int, height: c_int) *JanRenderer;
//pub const janRenderer_delete = *const fn (self: *JanRenderer) void;
//pub const janRenderer_run = *const fn (self: *JanRenderer) void;

pub extern fn jrNew(applicationName: [*:0]const u8, width: c_int, height: c_int) callconv(.c) *JanRenderer;
pub extern fn jrDelete(self: *JanRenderer) callconv(.c) void;
pub extern fn jrRun(self: *JanRenderer) callconv(.c) void;
