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

const adt = @import("adt.zig");
const tps = @import("types.zig");
const c = @import("cdefs.zig").c;
const gAllocator = @import("alloc.zig").gAllocator;

pub const PlayerType = enum {
    LOCAL,
    REMOTE,
    COMPUTER,
};

pub const Snake = struct {
    sprites: *adt.GenericLL,
    moveStep: c_int,
    team: c_int,
    // num is how many sprites (heroes or baddies) form the snake.
    num: c_int,
    buffs: [tps.BUFF_END]c_int, // r.c. - verified these should stay integers
    score: *tps.Score,
    playerType: PlayerType,

    // TODO: r.c. introduce Zig helper methods like below to check if any defense left.
    // const Self = @This();

    // pub fn hasDefense(self: *const Self) bool {
    //     return self.buffs[tps.BUFF_DEFENSE] > 0;
    // }
};

pub fn initSnake(snake: *Snake, step: c_int, team: c_int, playerType: PlayerType) void {
    snake.moveStep = step;
    snake.team = team;
    snake.num = 0;
    @memset(snake.buffs[0..], 0);
    snake.sprites = tps.createLinkList();
    snake.score = tps.createScore();
    snake.playerType = playerType;
}

pub fn createSnake(step: c_int, team: c_int, playerType: PlayerType) *Snake {
    const self = gAllocator.create(Snake) catch unreachable;
    initSnake(self, step, team, playerType);
    return self;
}
