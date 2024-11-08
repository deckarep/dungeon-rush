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

const ll = @import("linkedlist.zig");
const tps = @import("types.zig");
const c = @import("cdefs.zig").c;
const spr = @import("sprite.zig");
const gAllocator = @import("alloc.zig").gAllocator;

pub const PlayerType = enum {
    LOCAL,
    REMOTE,
    COMPUTER,
};

pub const Snake = struct {
    sprites: *ll.GenericLL,
    moveStep: c_int,
    team: c_int,
    // NOTE: r.c. - changed to be a getter method, cleaner and simpler.
    // Additionally, the Zig linked-list has a count built-in so it's tracked
    // for free!

    // num is how many sprites (heroes or baddies) form the snake.
    // num: c_int,
    buffs: [tps.BUFF_END]c_int, // r.c. - verified these should stay integers
    score: *tps.Score,
    playerType: PlayerType,

    // TODO: r.c. introduce Zig helper methods like below to check if any defense left.
    const Self = @This();

    // pub fn hasDefense(self: *const Self) bool {
    //     return self.buffs[tps.BUFF_DEFENSE] > 0;
    // }

    pub fn create(step: c_int, team: c_int, playerType: PlayerType) *Self {
        const snake = createSnake(step, team, playerType);
        initSnake(snake, step, team, playerType);
        return snake;
    }

    pub fn deinit(self: *Self) void {
        var p = self.sprites.first;
        while (p) |node| : (p = node.next) {
            const sprite: *spr.Sprite = @alignCast(@ptrCast(node.data.?));
            gAllocator.destroy(sprite);
            node.data = null;
        }

        tps.destroyLinkList(self.sprites);
        //snake.sprites = null; // currently it's non-nullable.
        tps.destroyScore(self.score);
        //snake.score = null; // currently it's non-nullable.
        // std.log.info("destroySnake: Freeing snake at address: {*}", .{snake});
        gAllocator.destroy(self);
    }

    /// This returns the number of sprites that are part of the player (snake).
    /// Original Comment: num is how many sprites (heroes or baddies) form the snake.
    pub fn num(self: *const Self) c_int {
        // NOTE: should be a usize, but it will require too much casting
        // for now, I'll leave as a c_int until I migrate away from c_int.
        return @intCast(self.sprites.len);
    }
};

pub fn initSnake(snake: *Snake, step: c_int, team: c_int, playerType: PlayerType) void {
    snake.moveStep = step;
    snake.team = team;
    //snake.num = 0;
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
