const std = @import("std");
const stdout = std.io.getStdOut().writer();

const c = @import("c_headers.zig").c;
const rand = @import("std").rand;
const meta = @import("std").meta;

const types = @import("types.zig");

// Extern for now.
pub extern var spriteSnake: [c.SPRITES_MAX_NUM]*c.Snake;
pub extern var bullets: ?*c.LinkList;
pub extern var GAME_WIN_NUM: c_int;
pub extern var gameLevel: c_int;
pub extern var stage: c_int;
pub extern var spritesCount: c_int;
pub extern var spritesSetting: c_int;
pub extern var bossSetting: c_int;
pub extern var herosSetting: c_int;
pub extern var flasksSetting: c_int;

pub extern var GAME_LUCKY: f64;
pub extern var GAME_DROPOUT_YELLOW_FLASKS: f64;
pub extern var GAME_DROPOUT_WEAPONS: f64;
pub extern var GAME_TRAP_RATE: f64;
pub extern var AI_LOCK_LIMIT: f64;
pub extern var GAME_MONSTERS_HP_ADJUST: f64;
pub extern var GAME_MONSTERS_WEAPON_BUFF_ADJUST: f64;
pub extern var GAME_MONSTERS_GEN_FACTOR: f64;

pub fn setLevel(level: c_int) void {
    const levelFloat: f64 = @intToFloat(f64, level);
    const stageFloat: f64 = @intToFloat(f64, stage);

    gameLevel = level;
    spritesSetting = 25;
    bossSetting = 2;
    herosSetting = 8;
    flasksSetting = 6;
    GAME_LUCKY = 1;
    GAME_DROPOUT_YELLOW_FLASKS = 0.3;
    GAME_DROPOUT_WEAPONS = 0.7;
    GAME_TRAP_RATE = 0.005 * (levelFloat + 1);
    GAME_MONSTERS_HP_ADJUST = 1 + levelFloat * 0.8 + stageFloat * levelFloat * 0.1;
    GAME_MONSTERS_GEN_FACTOR = 1 + levelFloat * 0.5 + stageFloat * levelFloat * 0.05;
    GAME_MONSTERS_WEAPON_BUFF_ADJUST = 1 + levelFloat * 0.8 + stageFloat * levelFloat * 0.02;
    AI_LOCK_LIMIT = @maximum(1, 7 - levelFloat * 2 - stageFloat / 2);
    GAME_WIN_NUM = 10 + level * 5 + stage * 3;
    if (level == 0) {
        // do nothing.
    } else if (level == 1) {
        GAME_DROPOUT_WEAPONS = 0.98;
        herosSetting = 5;
        flasksSetting = 4;
        spritesSetting = 28;
        bossSetting = 3;
    } else if (level == 2) {
        GAME_DROPOUT_WEAPONS = 0.98;
        GAME_DROPOUT_YELLOW_FLASKS = 0.3;
        spritesSetting = 28;
        herosSetting = 5;
        flasksSetting = 3;
        bossSetting = 5;
    }
    spritesSetting += @divTrunc(stage, 2) * (level + 1);
    bossSetting += @divTrunc(stage, 3);
}

pub fn startGame(localPlayers: c_int, remotePlayers: c_int, localFirst: bool) [*c][*c]c.Score {
    var scores: [*c][*c]c.Score = @ptrCast([*c][*c]c.Score, @alignCast(meta.alignment([*c]c.Score), c.malloc(@sizeOf([*c]c.Score) * @intCast(c_ulong, localPlayers))));

    var i: usize = 0;
    while (i < localPlayers) : (i += 1) {
        scores[i] = c.createScore();
    }

    var status: c_int = 0;
    stage = 0;

    while (true) {
        c.initGame(localPlayers, remotePlayers, localFirst);
        setLevel(gameLevel);
        status = c.gameLoop();
        var j: usize = 0;
        while (j < localPlayers) : (j += 1) {
            c.addScore(scores[j], spriteSnake[j].*.score);
        }
        c.destroyGame(status);
        stage += 1;

        // Quit to previous screen.
        if (status != 0) {
            break;
        }
    }

    return scores;
}

pub fn destroySnake(snake: *c.Snake) void {
    if (bullets) |someBullets| {
        var p: ?*c.LinkNode = someBullets.*.head;
        while (p) |someP| {
            var bullet: *c.Bullet = @ptrCast(*c.Bullet, @alignCast(meta.alignment(*c.Bullet), someP.*.element));
            if (bullet.*.owner == snake) {
                bullet.*.owner = null;
            }
            p = someP.*.nxt;
        }
    }

    var p: ?*c.LinkNode = snake.*.sprites.*.head;
    while (p) |someP| {
        var sprite: *c.Sprite = @ptrCast(*c.Sprite, @alignCast(meta.alignment(*c.Sprite), someP.*.element));
        c.free(sprite);
        someP.*.element = null;
        p = someP.*.nxt;
    }

    types.destroyLinkList(snake.*.sprites);
    snake.*.sprites = null;
    types.destroyScore(snake.*.score);
    snake.*.score = null;
    c.free(snake);
}
