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

const tps = @import("types.zig");
const spr = @import("sprite.zig");
const pl = @import("player.zig");

pub const AI_PATH_RANDOM = 0.01;
pub const AI_PREDICT_STEPS = 38;
pub const AI_DECIDE_RATE = 4;

pub var AI_LOCK_LIMIT: f64 = undefined;

pub const Choice = struct {
    value: c_int,
    direction: tps.Direction,
};

pub fn trapVerdict(sprite: *spr.Sprite) c_int {
    _ = sprite;
}

pub fn getPowerfulPlayer() c_int {}

pub fn balanceVerdict(sprite: *spr.Sprite, id: c_int) c_int {
    _ = sprite;
    _ = id;
}

pub fn testOneMove(snake: *pl.Snake, direction: tps.Direction) c_int {
    _ = snake;
    _ = direction;
}

pub fn compareChoiceByValue(x: *const anyopaque, y: *const anyopaque) c_int {
    const a: *Choice = @alignCast(@ptrCast(x));
    const b: *Choice = @alignCast(@ptrCast(y));

    return b.value - a.value;
}

pub fn AiInput(snake: *.pl.Snake) void {
    _ = snake;
}
