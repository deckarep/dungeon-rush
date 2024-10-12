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
