const prng = @import("prng.zig");
const c = @import("cdefs.zig").c;
const std = @import("std");
const res = @import("res.zig");
const ui = @import("ui.zig");

pub fn main() !void {
    prng.prngSrand(@as(c_uint, @bitCast(@as(c_int, @truncate(c.time(null))))));
    std.log.info("Hello from DungeonRush Zig-CC v2!", .{});
    defer res.cleanup();

    if (!res.init()) {
        _ = c.printf("Failed to initialize!\n");
    } else {
        if (!try res.loadMedia()) {
            _ = c.printf("Failed to load media!\n");
        } else {
            ui.mainUi();
        }
    }
}
