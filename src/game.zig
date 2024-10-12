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

fn setLevel(level: c_int) void {
    gameLevel = level;
    spritesSetting = 25;
    bossSetting = 2;
    herosSetting = 8;
    flasksSetting = 6;
    GAME_LUCKY = 1.0;
    GAME_DROPOUT_YELLOW_FLASKS = 0.3;
    GAME_DROPOUT_WEAPONS = 0.7;
    GAME_TRAP_RATE = 0.005 * (level + 1);
    GAME_MONSTERS_HP_ADJUST = 1 + level * 0.8 + stage * level * 0.1;
    GAME_MONSTERS_GEN_FACTOR = 1 + level * 0.5 + stage * level * 0.05;
    GAME_MONSTERS_WEAPON_BUFF_ADJUST = 1 + level * 0.8 + stage * level * 0.02;
    ai.AI_LOCK_LIMIT = @max(1, 7 - level * 2 - stage / 2);
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
    spritesSetting += stage / 2 * (level + 1);
    bossSetting += stage / 3;
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

    // TODO!!!
    // apply buff
    //if (snake->buffs[BUFF_DEFFENCE])
    //     shieldSprite(sprite, snake->buffs[BUFF_DEFFENCE]);
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
