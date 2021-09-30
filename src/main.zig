const c = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_mixer.h");
    @cInclude("SDL_image.h");
    @cInclude("SDL_net.h");
    @cInclude("SDL_ttf.h");
});

const std = @import("std");
const assert = @import("std").debug.assert;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello Dungeon Rush Zig!!!\n", .{});
}