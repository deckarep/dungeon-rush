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
const hlp = @import("helper.zig");
const res = @import("res.zig");
const mp = @import("map.zig");
const gm = @import("game.zig");
const ren = @import("render.zig");

pub const AI_PATH_RANDOM = 0.01;
pub const AI_PREDICT_STEPS = 38;
pub const AI_DECIDE_RATE = 4;

pub var AI_LOCK_LIMIT: f64 = undefined;

pub const Choice = struct {
    value: c_int,
    direction: tps.Direction,
};

pub fn trapVerdict(sprite: *spr.Sprite) c_int {
    var ret: c_int = 0;
    const x: c_int = sprite.x;
    const y: c_int = sprite.y;

    const box = hlp.getSpriteFeetBox(sprite);
    var block = box;

    var dx: c_int = -1;
    while (dx <= 1) : (dx += 1) {
        var dy: c_int = -1;
        while (dy <= 1) : (dy += 1) {
            const xx: c_int = @divTrunc(x, res.UNIT) + dx;
            const yy: c_int = @divTrunc(y, res.UNIT) + dy;
            if (hlp.inr(xx, 0, res.n - 1) and hlp.inr(yy, 0, res.m - 1)) {
                block = hlp.getMapRect(xx, yy);
                if (hlp.RectRectCross(&box, &block) and mp.hasMap[@intCast(xx)][@intCast(yy)] and
                    gm.map[@intCast(xx)][@intCast(yy)].bp == .BLOCK_TRAP)
                {
                    ret += @as(c_int, @intFromBool(gm.map[@intCast(xx)][@intCast(yy)].enable)) + 1;
                }
            }
        }
    }
    return ret;
}

pub fn getPowerfulPlayer() c_int {
    var maxNum: c_int = 0;
    var mxCount: c_int = 0;
    var id: c_int = -1;

    for (0..@intCast(gm.playersCount)) |i| {
        const num = gm.spriteSnake[i].?.num();
        if (num > maxNum) {
            maxNum = num;
            mxCount = 1;
            id = @intCast(i);
        } else if (num == maxNum) {
            mxCount += 1;
        }
    }

    if (id != -1 and mxCount == 1) {
        if (@as(f64, @floatFromInt(gm.spriteSnake[@intCast(id)].?.num())) >= AI_LOCK_LIMIT) {
            return id;
        } else {
            return -1;
        }
    } else {
        return -1;
    }
}

pub fn balanceVerdict(sprite: *spr.Sprite, id: c_int) c_int {
    if (id == -1) return 0;

    if (gm.spriteSnake[@intCast(id)].?.sprites.first == null) return 0;

    var ret: c_int = 0;
    const player: *spr.Sprite = @alignCast(@ptrCast(gm.spriteSnake[@intCast(id)].?.sprites.first.?.data.?));
    if (player.x < sprite.x and sprite.direction == .LEFT) ret += 1;
    if (player.x > sprite.x and sprite.direction == .RIGHT) ret += 1;
    if (player.y > sprite.y and sprite.direction == .DOWN) ret += 1;
    if (player.y < sprite.y and sprite.direction == .UP) ret += 1;
    return ret;
}

pub fn testOneMove(snake: *pl.Snake, direction: tps.Direction) c_int {
    const snakeHead: *spr.Sprite = @alignCast(@ptrCast(snake.sprites.first.?.data.?));
    const recover = snakeHead.direction;
    snakeHead.direction = direction;

    var crush: c_int = 0;
    var trap: c_int = 0;
    var playerBalance: c_int = 0;

    const powerful = getPowerfulPlayer();

    for (1..(AI_PREDICT_STEPS + 1)) |i| {
        gm.moveSprite(snakeHead, snake.moveStep * @as(c_int, @intCast(i)));
        ren.updateAnimationOfSprite(snakeHead);
        crush -= @as(c_int, @intFromBool(gm.crushVerdict(snakeHead, false, true))) * 1000;
        trap -= trapVerdict(snakeHead);
        playerBalance += balanceVerdict(snakeHead, powerful) * 10;

        // revoke position
        gm.moveSprite(snakeHead, -snake.moveStep * @as(c_int, @intCast(i)));
        ren.updateAnimationOfSprite(snakeHead);
    }

    snakeHead.direction = recover;
    return trap + crush + playerBalance;
}

pub fn compareChoiceByValue(x: *const anyopaque, y: *const anyopaque) c_int {
    const a: *Choice = @alignCast(@ptrCast(x));
    const b: *Choice = @alignCast(@ptrCast(y));

    return b.value - a.value;
}

// r.c. added by me, this should go away...the enum needs an int type.
// but not sure what int type to use just yet.
fn intToDir(i: c_int) tps.Direction {
    return switch (i) {
        0 => tps.Direction.LEFT,
        1 => tps.Direction.RIGHT,
        2 => tps.Direction.UP,
        3 => tps.Direction.DOWN,
        else => unreachable,
    };
}

pub fn AiInput(snake: *pl.Snake) void {
    const snakeHead: *spr.Sprite = @alignCast(@ptrCast(snake.sprites.first.?.data.?));
    const currentDirection: c_int = switch (snakeHead.direction) {
        .LEFT => 0,
        .RIGHT => 1,
        .UP => 2,
        .DOWN => 3,
    };

    const originValue = testOneMove(snake, snakeHead.direction);
    var change = originValue < 0;

    if (hlp.randDouble() < AI_PATH_RANDOM) change = true;

    if (change) {
        // NOTE: r.c. - This doesn't need to be a static array as it is in the C version.
        var choices: [4]Choice = undefined;
        var count: usize = 0;

        var i: c_int = 0;
        //for (int i = LEFT; i <= DOWN; i++){
        while (i <= 3) : (i += 1) {
            if (i != currentDirection and (i ^ 1) != currentDirection) {
                const value = testOneMove(snake, intToDir(@intCast(i)));
                if (value >= originValue) {
                    choices[count] = .{ .value = value, .direction = intToDir(i) };
                    count += 1;
                }
            }
        }

        if (count > 0) {
            var maxValue = choices[0].value;
            var nowChoice: usize = 0;

            for (0..count) |ii| {
                if (choices[ii].value > maxValue) {
                    maxValue = choices[ii].value;
                    nowChoice = ii;
                }
            }

            if (maxValue > originValue)
                tps.changeSpriteDirection(
                    snake.sprites.first.?,
                    choices[nowChoice].direction,
                );
        }
    }
}
