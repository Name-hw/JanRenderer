const std = @import("std");
const JanRenderer = @import("JanRenderer.zig");

pub fn main() !void {
    //var JanRenderer_lib = try std.DynLib.open("JanRenderer.dll");
    //const janRenderer_new: Types.janRenderer_new = JanRenderer_lib.lookup(Types.janRenderer_new, "janRenderer_new") orelse return error.LookupFailed;
    //const janRenderer_run: Types.janRenderer_run = JanRenderer_lib.lookup(Types.janRenderer_run, "janRenderer_run") orelse return error.LookupFailed;
    //const janRenderer_destroy: Types.janRenderer_delete = JanRenderer_lib.lookup(Types.janRenderer_delete, "janRenderer_delete") orelse return error.LookupFailed;

    const pJanRenderer = JanRenderer.jrNew("test", 800, 600);

    std.debug.print("{s}, {d}, {d}\n", .{ pJanRenderer.applicationName, pJanRenderer.width, pJanRenderer.height });

    JanRenderer.jrRun(pJanRenderer);

    JanRenderer.jrDelete(pJanRenderer);
}
