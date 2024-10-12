const std = @import("std");
const pl = @import("player.zig");
const tps = @import("types.zig");
const res = @import("res.zig");
const c = @import("cdefs.zig").c;
const adt = @import("adt.zig");
const spr = @import("sprite.zig");
const blt = @import("bullet.zig");
const ren = @import("render.zig");
const mp = @import("map.zig");
const ai = @import("ai.zig");

const SPRITES_MAX_NUM = 1024;
const MOVE_STEP = 2;

// Map
pub var map: [mp.MAP_SIZE][mp.MAP_SIZE]tps.Block = undefined;
var spriteSnake: [SPRITES_MAX_NUM]*pl.Snake = undefined;
var bullets: ?*adt.LinkList = null;

pub var gameLevel: c_int = undefined;
var stage: c_int = undefined;
var spritesCount: c_int = undefined;
var playersCount: c_int = undefined;
var flasksCount: c_int = undefined;
var herosCount: c_int = undefined;
var flasksSetting: c_int = undefined;

var herosSetting: c_int = undefined;
var spritesSetting: c_int = undefined;
var bossSetting: c_int = undefined;

// Win
var GAME_WIN_NUM: c_int = undefined;
var termCount: c_int = undefined;
var status: c_int = undefined;
var willTerm: bool = undefined;

// Drop rate
var GAME_LUCKY: f64 = undefined;
var GAME_DROPOUT_YELLOW_FLASKS: f64 = undefined;
var GAME_DROPOUT_WEAPONS: f64 = undefined;
var GAME_TRAP_RATE: f64 = undefined;
var GAME_MONSTERS_HP_ADJUST: f64 = undefined;
var GAME_MONSTERS_WEAPON_BUFF_ADJUST: f64 = undefined;
var GAME_MONSTERS_GEN_FACTOR: f64 = undefined;

pub fn setLevel(level: c_int) void {
    const fLvl: f64 = @floatFromInt(level);
    const fStg: f64 = @floatFromInt(stage);

    gameLevel = level;
    spritesSetting = 25;
    bossSetting = 2;
    herosSetting = 8;
    flasksSetting = 6;
    GAME_LUCKY = 1.0;
    GAME_DROPOUT_YELLOW_FLASKS = 0.3;
    GAME_DROPOUT_WEAPONS = 0.7;
    GAME_TRAP_RATE = 0.005 * (fLvl + 1);
    GAME_MONSTERS_HP_ADJUST = 1 + fLvl * 0.8 + fStg * fLvl * 0.1;
    GAME_MONSTERS_GEN_FACTOR = 1 + fLvl * 0.5 + fStg * fLvl * 0.05;
    GAME_MONSTERS_WEAPON_BUFF_ADJUST = 1 + fLvl * 0.8 + fStg * fLvl * 0.02;
    ai.AI_LOCK_LIMIT = @max(1, 7 - fLvl * 2 - fStg / 2);
    GAME_WIN_NUM = 10 + level * 5 + stage * 3;
    if (level == 0) {
        // wow, such empty.
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

pub fn startGame(localPlayers: c_int, remotePlayers: c_int, localFirst: bool) [*]*tps.Score {
    _ = remotePlayers;
    _ = localFirst;
    std.log.info("startGame!! was reached!", .{});

    // This gets free'd in the storage.zig code (not built yet!)
    const scores: [*]*tps.Score = @alignCast(@ptrCast(c.malloc(
        @sizeOf(*tps.Score) * @as(usize, @intCast(localPlayers)),
    )));
    return scores;
}

pub fn appendSpriteToSnake(
    snake: *pl.Snake,
    sprite_id: c_int,
    x: c_int, // x ,y, dir only matter when empty snake
    y: c_int,
    direction: tps.Direction,
) void {
    snake.num += 1;
    snake.score.got += 1;
    var newX = x;
    var newY = y;

    // at head
    const node: *adt.LinkNode = @alignCast(@ptrCast(c.malloc(@sizeOf(adt.LinkNode))));
    tps.initLinkNode(node);

    // create a sprite
    var snakeHead: ?*spr.Sprite = null;
    if (snake.sprites.head != null) {
        snakeHead = @alignCast(@ptrCast(snake.sprites.head.?.element));
        newX = snakeHead.?.x;
        newY = snakeHead.?.y;
        const delta = @divTrunc((snakeHead.?.ani.origin.width * ren.SCALE_FACTOR +
            res.commonSprites[@intCast(sprite_id)].ani.origin.width * ren.SCALE_FACTOR), 2);
        if (snakeHead.?.direction == .LEFT) {
            newX -= delta;
        } else if (snakeHead.?.direction == .RIGHT) {
            newX += delta;
        } else if (snakeHead.?.direction == .UP) {
            newY -= delta;
        } else {
            newY += delta;
        }
    }
    const sprite = spr.createSprite(&res.commonSprites[@intCast(sprite_id)], newX, newY);
    sprite.direction = direction;
    if (direction == .LEFT) {
        sprite.face = .LEFT;
    }
    if (snakeHead != null) {
        sprite.direction = snakeHead.?.direction;
        sprite.face = snakeHead.?.face;
        sprite.ani.currentFrame = snakeHead.?.ani.currentFrame;
    }
    // insert the sprite
    node.element = sprite;
    tps.pushLinkNodeAtHead(snake.sprites, node);

    // push ani
    ren.pushAnimationToRender(ren.RENDER_LIST_SPRITE_ID, sprite.ani);

    // TODO: I think the buffs array should be booleans (possibly, confirm later)
    if (snake.buffs[tps.BUFF_DEFENCE] == 1) {
        shieldSprite(sprite, snake.buffs[tps.BUFF_DEFENCE]);
    }
}

pub fn initPlayer(playerType: pl.PlayerType) void {
    spritesCount += 1;
    spriteSnake[playersCount] = pl.createSnake(MOVE_STEP, playersCount, playerType);
    const p = spriteSnake[playersCount];
    appendSpriteToSnake(p, res.SPRITE_KNIGHT, res.SCREEN_WIDTH / 2, res.SCREEN_HEIGHT / 2 + playersCount * 2 * res.UNIT, .RIGHT);
    playersCount += 1;
}

pub fn destroySnake(snake: *pl.Snake) void {
    if (bullets) |bu| {
        var p = bu.head;
        while (p != null) : (p = p.?.nxt) {
            const bullet: *blt.Bullet = @alignCast(@ptrCast(p.?.element.?));
            if (bullet.owner == snake) {
                bullet.owner = null;
            }
        }
    }

    var p = snake.sprites.head;
    while (p != null) : (p = p.?.nxt) {
        const sprite: *spr.Sprite = @alignCast(@ptrCast(p.?.element.?));
        c.free(sprite);
        p.?.element = null;
    }
    tps.destroyLinkList(snake.sprites);
    //snake.sprites = null; // currently it's non-nullable.
    tps.destroyScore(snake.score);
    //snake.score = null; // currently it's non-nullable.
    c.free(snake);
}

// Put buff animation on snake

fn shieldSprite(sprite: *spr.Sprite, duration: c_int) void {
    const ani = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_EFFECT_ID],
        &res.textures[res.RES_HOLY_SHIELD],
        null,
        .LOOP_LIFESPAN,
        40,
        sprite.x,
        sprite.y,
        c.SDL_FLIP_NONE,
        0,
        .AT_BOTTOM_CENTER,
    );
    ren.bindAnimationToSprite(ani, sprite, true);
    ani.lifeSpan = duration;
}

pub fn shieldSnake(snake: *pl.Snake, duration: c_int) void {
    if (snake.buffs[tps.BUFF_DEFENCE] == 1) return;
    snake.buffs[tps.BUFF_DEFENCE] += duration;

    const p = snake.sprites.head;
    while (p != null) : (p = p.nxt) {
        const sprite: *spr.Sprite = @alignCast(@ptrCast(p.element));
        shieldSprite(sprite, duration);
    }
}
