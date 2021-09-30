const c = @cImport({
    @cInclude("SDL.h");
    @cInclude("SDL_mixer.h");
    @cInclude("SDL_image.h");
    @cInclude("SDL_net.h");
    @cInclude("SDL_ttf.h");
});

extern fn cmain(argv: [*c][*c]u8, argc: c_int) c_int;
extern fn add(a:c_int, b:c_int) c_int;

const std = @import("std");
const assert = @import("std").debug.assert;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello Dungeon Rush Zig!!!\n", .{});

    _ = cmain(null, @intCast(c_int, std.os.argv.len));

    var result:c_int = add(4, 6);
    try stdout.print("Here's the result: {d}\n", .{result});
}