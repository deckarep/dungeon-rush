const c = @import("c_headers.zig").c;

// const c_dr = @cImport({
//     @cInclude("res.h");
//     @cInclude("ui.h");
// });

const rnd = @import("prng.zig");
const ui = @import("ui.zig");

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
    if (!c.init()) {
        defer c.cleanup();
        try stdout.print("Failed to initialize!\n", .{});
    } else {
        // Load media
        if (!c.loadMedia()) {
            try stdout.print("Failed to load media!\n", .{});
        } else {
            try ui.mainUi();
        }
    }
}