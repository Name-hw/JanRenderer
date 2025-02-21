const std = @import("std");
const Types = @import("Types.zig");

pub fn main() !void {
    var JanRenderer_lib = try std.DynLib.open("JanRenderer.dll");
    const janRenderer_new: Types.janRenderer_new = JanRenderer_lib.lookup(Types.janRenderer_new, "janRenderer_new") orelse return error.LookupFailed;
    const janRenderer_run: Types.janRenderer_run = JanRenderer_lib.lookup(Types.janRenderer_run, "janRenderer_run") orelse return error.LookupFailed;
    const janRenderer_destroy: Types.janRenderer_delete = JanRenderer_lib.lookup(Types.janRenderer_delete, "janRenderer_delete") orelse return error.LookupFailed;

    const pJanRenderer = janRenderer_new("test", 800, 600);

    std.debug.print("{s}, {d}, {d}\n", .{ pJanRenderer.applicationName, pJanRenderer.width, pJanRenderer.height });

    janRenderer_run(pJanRenderer);

    janRenderer_destroy(pJanRenderer);

    JanRenderer_lib.close();
}
