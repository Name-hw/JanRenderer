const std = @import("std");
const fs = std.fs;
const JanRenderer = @import("JanRenderer.zig");

pub fn main(init: std.process.Init) !void {
    //var JanRenderer_lib = try std.DynLib.open("JanRenderer.dll");
    //const janRenderer_new: Types.janRenderer_new = JanRenderer_lib.lookup(Types.janRenderer_new, "janRenderer_new") orelse return error.LookupFailed;
    //const janRenderer_run: Types.janRenderer_run = JanRenderer_lib.lookup(Types.janRenderer_run, "janRenderer_run") orelse return error.LookupFailed;
    //const janRenderer_destroy: Types.janRenderer_delete = JanRenderer_lib.lookup(Types.janRenderer_delete, "janRenderer_delete") orelse return error.LookupFailed;
    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const root_dir = try cwd.openDir(io, "../../", .{});
    try std.process.setCurrentDir(io, root_dir);

    const pJanRenderer = JanRenderer.jrNew("test", 800, 600);

    std.debug.print("{s}, {d}, {d}\n", .{ pJanRenderer.applicationName, pJanRenderer.width, pJanRenderer.height });

    JanRenderer.jrRun(pJanRenderer);

    JanRenderer.jrDelete(pJanRenderer);
}
