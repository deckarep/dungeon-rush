const c = @import("c_headers.zig").c;

const rnd = @import("prng.zig");
const ui = @import("ui.zig");
const res = @import("res.zig");

const assert = @import("std").debug.assert;
const std = @import("std");
const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    try stdout.print("Hello Dungeon Rush Zig!!!\n", .{});
    try start();
}

fn start() !void {
    // TODO: should use time(NULL) for a seed.
    rnd.prngSrand(112112);
    // Start up SDL and create window
    if (!res.init()) {
        defer res.cleanup();
        try stdout.print("Failed to initialize!\n", .{});
    } else {
        // Load media
        if (!res.loadMedia()) {
            try stdout.print("Failed to load media!\n", .{});
        } else {
            try ui.mainUi();
        }
    }
}
