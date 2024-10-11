const adt = @import("adt.zig");
const tps = @import("types.zig");
const c = @import("cdefs.zig").c;

pub const PlayerType = enum {
    LOCAL,
    REMOTE,
    COMPUTER,
};

pub const Snake = struct {
    sprites: *adt.LinkList,
    moveStep: c_int,
    team: c_int,
    num: c_int,
    buffs: [tps.BUFF_END]c_int,
    score: *tps.Score,
    playerType: PlayerType,
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
    const self: *Snake = @alignCast(@ptrCast(c.malloc(@sizeOf(Snake))));
    initSnake(self, step, team, playerType);
    return self;
}
