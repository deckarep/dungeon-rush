// Open Source Initiative OSI - The MIT License (MIT):Licensing

// The MIT License (MIT)
// Copyright (c) 2024 Ralph Caraveo (deckarep@gmail.com)

// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

const prng = @import("prng.zig");
const c = @import("cdefs.zig").c;
const std = @import("std");
const res = @import("res.zig");
const ui = @import("ui.zig");
const alloc = @import("alloc.zig");

pub fn main() !void {
    std.log.info(res.nameOfTheGame, .{});
    prng.prngSrand(@as(c_uint, @bitCast(@as(c_int, @truncate(c.time(null))))));

    defer {
        std.log.info("checking for leaks on gAllocator...", .{});
        const deinit_status = alloc.gpa.deinit();
        if (deinit_status == .leak) {
            std.log.err("leaks were detected :(", .{});
        } else {
            std.log.info("No leaks detected. :)", .{});
        }
    }

    defer {
        std.log.info("cleaning up all resources!", .{});
        res.cleanup();
    }

    if (!res.init()) {
        std.log.err("Failed to init SDL and/or the game.", .{});
    } else {
        if (!try res.loadMedia()) {
            std.log.err("Failed to load media.", .{});
        } else {
            try ui.mainUi();
        }
    }
}
