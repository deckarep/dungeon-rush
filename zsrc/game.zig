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

const std = @import("std");
const pl = @import("player.zig");
const tps = @import("types.zig");
const res = @import("res.zig");
const adt = @import("adt.zig");
const spr = @import("sprite.zig");
const blt = @import("bullet.zig");
const ren = @import("render.zig");
const mp = @import("map.zig");
const ai = @import("ai.zig");
const aud = @import("audio.zig");
const wp = @import("weapons.zig");
const hlp = @import("helper.zig");
const c = @import("cdefs.zig").c;
const th = @import("throttler.zig");
const gAllocator = @import("alloc.zig").gAllocator;

const SPIKE_ANI_DURATION = 20;
const SPIKE_OUT_INTERVAL = 120;
const SPIKE_TIME_MASK = 600;
const SPRITES_MAX_NUM = 1024;
const MOVE_STEP = 3;
const GAME_MONSTERS_TEAM = 9;
pub const GAME_MAP_RELOAD_PERIOD = 120;
pub const MAX_PLAYERS_NUM = 2;
const GAME_HP_MEDICINE_EXTRA_DELTA = 33;
const GAME_HP_MEDICINE_DELTA = 55;
const GAME_FROZEN_DAMAGE_K = 0.1;
const GAME_BUFF_ATTACK_K = 2.5;
const GAME_BUFF_DEFENSE_K = 2;

// Map
pub var map: [mp.MAP_SIZE][mp.MAP_SIZE]tps.Block = undefined;
var itemMap: [mp.MAP_SIZE][mp.MAP_SIZE]tps.Item = undefined;
var hasEnemy: [mp.MAP_SIZE][mp.MAP_SIZE]bool = undefined;
const spikeDamage = 1;
pub var spriteSnake: [SPRITES_MAX_NUM]?*pl.Snake = undefined;

var bullets: ?*adt.GenericLL = null;

pub var gameLevel: c_int = undefined;
pub var stage: c_int = undefined;
pub var spritesCount: c_int = undefined;
pub var playersCount: c_int = undefined;
var flasksCount: c_int = undefined;
var herosCount: c_int = undefined;
var flasksSetting: c_int = undefined;

var herosSetting: c_int = undefined;
var spritesSetting: c_int = undefined;
var bossSetting: c_int = undefined;

// Win
pub var GAME_WIN_NUM: c_int = undefined;
var termCount: c_int = undefined;
var status: GameStatus = undefined;
var willTerm: bool = undefined;
pub var fps: f32 = 0;

// Drop rate
var GAME_LUCKY: f64 = undefined;
var GAME_DROPOUT_YELLOW_FLASKS: f64 = undefined;
var GAME_DROPOUT_WEAPONS: f64 = undefined;
var GAME_TRAP_RATE: f64 = undefined;
var GAME_MONSTERS_HP_ADJUST: f64 = undefined;
var GAME_MONSTERS_WEAPON_BUFF_ADJUST: f64 = undefined;
var GAME_MONSTERS_GEN_FACTOR: f64 = undefined;

// Bounder Box
pub const SPRITE_EFFECT_DELTA = 20;
pub const BIG_SPRITE_EFFECT_DELTA = 25;
pub const SPRITE_EFFECT_VERTICAL_DELTA = 6;
pub const SPRITE_EFFECT_FEET = 12;

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
    std.log.info("startGame!! was reached", .{});

    // NOTE: This gets free'd in the storage.zig code (not built yet!)
    const scores: [*]*tps.Score = @alignCast(@ptrCast(c.malloc(
        @sizeOf(*tps.Score) * @as(usize, @intCast(localPlayers)),
    )));

    for (0..@intCast(localPlayers)) |i| {
        scores[i] = tps.createScore();
    }

    var currentStatus: GameStatus = undefined;
    stage = 0;
    // NOTE: r.c.: ugly do-while converted to while with a break.
    while (true) {
        initGame(localPlayers, remotePlayers, localFirst);
        setLevel(gameLevel);
        currentStatus = gameLoop();
        for (0..@intCast(localPlayers)) |i| {
            tps.addScore(scores[i], spriteSnake[i].?.score);
        }
        destroyGame(currentStatus);
        stage += 1;
        if (currentStatus != .STAGE_CLEAR) break;
    }

    return scores;
}

pub fn appendSpriteToSnake(
    snake: *pl.Snake,
    spriteId: c_int,
    x: c_int, // x ,y, dir only matter when empty snake
    y: c_int,
    direction: tps.Direction,
) void {
    snake.num += 1;
    snake.score.got += 1;
    var newX = x;
    var newY = y;

    // at head
    //const node: *adt.LinkNode = @alignCast(@ptrCast(c.malloc(@sizeOf(adt.LinkNode))));
    const node = gAllocator.create(adt.GenericNode) catch unreachable;
    tps.initLinkNode(node);

    // create a sprite
    var snakeHead: ?*spr.Sprite = null;
    if (snake.sprites.first != null) {
        snakeHead = @alignCast(@ptrCast(snake.sprites.first.?.data));
        newX = snakeHead.?.x;
        newY = snakeHead.?.y;
        const delta = @divTrunc((snakeHead.?.ani.origin.width * ren.SCALE_FACTOR +
            res.commonSprites[@intCast(spriteId)].ani.origin.width * ren.SCALE_FACTOR), 2);
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
    const sprite = spr.createSprite(&res.commonSprites[@intCast(spriteId)], newX, newY);
    std.log.info("appendSpriteToSnake snake:{*}, sprite:{*}", .{ snake, sprite });
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
    //node.element = sprite;
    node.data = sprite;
    tps.pushLinkNodeAtHead(snake.sprites, node);

    // push ani
    ren.pushAnimationToRender(ren.RENDER_LIST_SPRITE_ID, sprite.ani);

    // TODO: I think the buffs array should be booleans (possibly, confirm later)
    if (snake.buffs[tps.BUFF_DEFENCE] > 0) {
        shieldSprite(sprite, snake.buffs[tps.BUFF_DEFENCE]);
    }
}

pub fn initPlayer(playerType: pl.PlayerType) void {
    spritesCount += 1;
    const p = pl.createSnake(MOVE_STEP, playersCount, playerType);
    spriteSnake[@intCast(playersCount)] = p;
    // r.c. - Unlike original game, this one starts with a random hero each round.
    const whichSprite = hlp.randInt(res.SPRITE_KNIGHT, res.SPRITE_LIZARD);
    appendSpriteToSnake(p, whichSprite, res.SCREEN_WIDTH / 2, res.SCREEN_HEIGHT / 2 + playersCount * 2 * res.UNIT, .RIGHT);
    playersCount += 1;
}

pub fn generateHeroItem(x: c_int, y: c_int) void {
    var xx = x;
    var yy = y;

    const heroId = hlp.randInt(res.SPRITE_KNIGHT, res.SPRITE_LIZARD);
    const ani: *tps.Animation = @ptrCast(@alignCast(c.malloc(@sizeOf(tps.Animation))));

    itemMap[@intCast(x)][@intCast(y)] = .{
        .type = .ITEM_HERO,
        .id = heroId,
        .belong = 0,
        .ani = ani,
    };

    const srcAni = res.commonSprites[@intCast(heroId)].ani;
    tps.copyAnimation(srcAni, ani);

    xx *= res.UNIT;
    yy *= res.UNIT;

    // NOTE: Dangerous (in original C-based code)
    // ani.origin--;

    // r.c. - this bothered me so much I had to ask him about it.
    // https://github.com/rapiz1/DungeonRush/issues/44

    // From @rapiz1:
    // "This is likely because textures are guaranteed to be stored in a particular order.
    // You can try to trace how textures for heroes are loaded. I guess that the decrement
    // here is to get a different orientation of the same hero character."

    // In the res.Textures array when they get loaded, they are always in this order
    // and the game always refer to them by their "run" resource id.
    // So when the game spawns it moves the pointer to pointer - 1.
    // This puts hero in idle animation while they're waiting to get picked up.
    // Later, if the hero is killed the pointer is put to: pointer + 1 and since
    // they are running it's the <char>_hit_anim.

    // <char>_idle_anim  - 1
    // <char>_run_anim   - 0
    // <char>_hit_anim   + 1

    // Zig replacement code (still dangerous btw):
    // Basically this code just moves the texture assignment to the previous created one
    // in the orignal res.textures array, I need to study the textures themselves to see
    // why @rapiz1 thought this was a good idea.

    // r.c. - this is how comments should be done around code that seems magical.
    // Context matters!
    const curPtr = @intFromPtr(ani.origin);
    // Effectively moves the pointer one Texture size less.
    const newPtr = curPtr - (@sizeOf(tps.Texture) * 1);
    ani.origin = @ptrFromInt(newPtr);

    ani.x = xx + (res.UNIT / 2);
    ani.y = yy + (res.UNIT - 3);
    ani.at = .AT_BOTTOM_CENTER;
    ren.pushAnimationToRender(ren.RENDER_LIST_SPRITE_ID, ani);
}

pub fn generateItem(x: c_int, y: c_int, @"type": tps.ItemType) void {
    var textureId: usize = res.RES_FLASK_BIG_RED;
    var id: c_int = 0;
    var belong: c_int = res.SPRITE_KNIGHT;

    if (@"type" == .ITEM_HP_MEDICINE) {
        textureId = res.RES_FLASK_BIG_RED;
    } else if (@"type" == .ITEM_HP_EXTRA_MEDICINE) {
        textureId = res.RES_FLASK_BIG_YELLOW;
    } else if (@"type" == .ITEM_WEAPON) {
        const kind = hlp.randInt(0, 5);
        switch (kind) {
            0 => {
                textureId = res.RES_ICE_SWORD;
                id = wp.WEAPON_ICE_SWORD;
                belong = res.SPRITE_KNIGHT;
            },
            1 => {
                textureId = res.RES_HOLY_SWORD;
                id = wp.WEAPON_HOLY_SWORD;
                belong = res.SPRITE_KNIGHT;
            },
            2 => {
                textureId = res.RES_THUNDER_STAFF;
                id = wp.WEAPON_THUNDER_STAFF;
                belong = res.SPRITE_WIZZARD;
            },
            3 => {
                textureId = res.RES_PURPLE_STAFF;
                id = wp.WEAPON_PURPLE_STAFF;
                belong = res.SPRITE_WIZZARD;
            },
            4 => {
                textureId = res.RES_GRASS_SWORD;
                id = wp.WEAPON_SOLID_CLAW;
                belong = res.SPRITE_LIZARD;
            },
            5 => {
                textureId = res.RES_POWERFUL_BOW;
                id = wp.WEAPON_POWERFUL_BOW;
                belong = res.SPRITE_ELF;
            },
            else => unreachable,
        }
    }

    const ani = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_MAP_ITEMS_ID],
        &res.textures[textureId],
        null,
        .LOOP_INFI,
        3,
        x * res.UNIT,
        y * res.UNIT,
        c.SDL_FLIP_NONE,
        0,
        .AT_BOTTOM_LEFT,
    );

    itemMap[@intCast(x)][@intCast(y)] = .{
        .type = @"type",
        .id = id,
        .belong = belong,
        .ani = ani,
    };
}

fn updateMap() void {
    const maskedTime = ren.renderFrames % SPIKE_TIME_MASK;

    for (0..res.SCREEN_WIDTH / res.UNIT) |i| {
        for (0..res.SCREEN_HEIGHT / res.UNIT) |j| {
            const ii: c_int = @intCast(i);
            const jj: c_int = @intCast(j);
            if (mp.hasMap[i][j] and map[i][j].bp == .BLOCK_TRAP) {
                if (maskedTime == 0) {
                    _ = ren.createAndPushAnimation(
                        &ren.animationsList[ren.RENDER_LIST_MAP_SPECIAL_ID],
                        &res.textures[res.RES_FLOOR_SPIKE_OUT_ANI],
                        null,
                        .LOOP_ONCE,
                        SPIKE_ANI_DURATION,
                        ii * res.UNIT,
                        jj * res.UNIT,
                        c.SDL_FLIP_NONE,
                        0,
                        .AT_TOP_LEFT,
                    );
                } else if (maskedTime == SPIKE_ANI_DURATION - 1) {
                    map[i][j].enable = true;
                    map[i][j].ani.origin = &res.textures[res.RES_FLOOR_SPIKE_ENABLED];
                } else if (maskedTime == SPIKE_ANI_DURATION + SPIKE_OUT_INTERVAL - 1) {
                    _ = ren.createAndPushAnimation(
                        &ren.animationsList[ren.RENDER_LIST_MAP_SPECIAL_ID],
                        &res.textures[res.RES_FLOOR_SPIKE_IN_ANI],
                        null,
                        .LOOP_ONCE,
                        SPIKE_ANI_DURATION,
                        ii * res.UNIT,
                        jj * res.UNIT,
                        c.SDL_FLIP_NONE,
                        0,
                        .AT_TOP_LEFT,
                    );
                    map[i][j].enable = false;
                    map[i][j].ani.origin = &res.textures[res.RES_FLOOR_SPIKE_DISABLED];
                }
            }
        }
    }
}

/// For each snake, decrement each of their "active" buffs which
/// is any buff greater than zero.
fn updateBuffDuration() void {
    for (0..@intCast(spritesCount)) |i| {
        const snake = spriteSnake[i].?;
        for (tps.BUFF_BEGIN..tps.BUFF_END) |j| {
            if (snake.buffs[j] > 0) {
                snake.buffs[j] -= 1;
            }
        }
    }
}

fn makeSpriteAttack(sprite: *spr.Sprite, snake: *pl.Snake) void {
    const weapon = sprite.weapon;

    // If we attacked recently, take a chill pill, don't attack again you jerk.
    const la: usize = @intCast(sprite.lastAttack);
    const gap: usize = @intCast(weapon.gap);
    if ((ren.renderFrames - la) < gap) {
        return;
    }

    var attacked = false;
    attack_end: for (0..@intCast(spritesCount)) |i| {
        // Not on the same team...
        if (snake.team != spriteSnake[i].?.team) {
            var p = spriteSnake[i].?.sprites.first;
            while (p != null) : (p = p.?.next) {
                const target: *spr.Sprite = @alignCast(@ptrCast(p.?.data));
                // Can the shooter's weapon reach the enemy?
                if (hlp.distance(
                    .{ .x = sprite.x, .y = sprite.y },
                    .{ .x = target.x, .y = target.y },
                ) > @as(f64, @floatFromInt(weapon.shootRange))) {
                    // If weapon can't reach, move on.
                    continue;
                }

                // Get the aim in radians.
                const rad: f64 = std.math.atan2(
                    @as(f64, @floatFromInt(target.y - sprite.y)),
                    @as(f64, @floatFromInt(target.x - sprite.x)),
                );

                if (weapon.wp == .WEAPON_SWORD_POINT or
                    weapon.wp == .WEAPON_SWORD_RANGE)
                {
                    const ani: *tps.Animation = @ptrCast(@alignCast(c.malloc(@sizeOf(tps.Animation))));
                    tps.copyAnimation(weapon.deathAni.?, ani);
                    // r.c. - Line commented out in original.
                    // ani->x = target->x, ani->y = target->y;
                    ren.bindAnimationToSprite(ani, target, false);
                    if (ani.angle != -1) {
                        ani.angle = rad * (180.0 / std.math.pi);
                    }
                    ren.pushAnimationToRender(ren.RENDER_LIST_EFFECT_ID, ani);
                    dealDamage(snake, spriteSnake[i].?, target, weapon.damage);
                    invokeWeaponBuff(snake, weapon, spriteSnake[i].?, weapon.damage);
                    attacked = true;
                    if (weapon.wp == .WEAPON_SWORD_POINT) {
                        break :attack_end;
                    }
                } else {
                    const bullet = blt.createBullet(
                        snake,
                        weapon,
                        sprite.x,
                        sprite.y,
                        rad,
                        snake.team,
                        // A bullet must have a flyAni, in theory at least.
                        weapon.flyAni.?,
                    );
                    tps.pushLinkNode(bullets.?, tps.createLinkNode(bullet));
                    ren.pushAnimationToRender(ren.RENDER_LIST_EFFECT_ID, bullet.ani);
                    attacked = true;
                    if (weapon.wp != .WEAPON_GUN_POINT_MULTI) {
                        break :attack_end;
                    }
                }
            }
        }
    }

    if (attacked) {
        if (weapon.birthAni) |birthAni| {
            const ani: *tps.Animation = @alignCast(@ptrCast(c.malloc(@sizeOf(tps.Animation))));
            tps.copyAnimation(birthAni, ani);
            ren.bindAnimationToSprite(ani, sprite, true);
            ani.at = .AT_BOTTOM_CENTER;
            ren.pushAnimationToRender(ren.RENDER_LIST_EFFECT_ID, ani);
        }

        if (weapon.wp == .WEAPON_SWORD_POINT or
            weapon.wp == .WEAPON_SWORD_RANGE)
        {
            aud.playAudio(@intCast(weapon.deathAudio));
        } else {
            aud.playAudio(@intCast(weapon.birthAudio));
        }

        sprite.lastAttack = @intCast(ren.renderFrames);
    }
}

fn makeSnakeAttack(snake: *pl.Snake) void {
    // Snek can't attack when frozen..pssh, exit function.
    if (snake.buffs[tps.BUFF_FROZEN] > 0) return;

    var p = snake.sprites.first;
    while (p) |node| : (p = node.next) {
        makeSpriteAttack(@alignCast(@ptrCast(node.data)), snake);
    }
}

fn isWin() bool {
    if (playersCount != 1) return false;
    return spriteSnake[0].?.num >= GAME_WIN_NUM;
}

const GameStatus = enum {
    STAGE_CLEAR,
    GAME_OVER,
};

fn setTerm(s: GameStatus) void {
    aud.stopBgm();

    switch (s) {
        .STAGE_CLEAR => aud.playAudio(res.AUDIO_WIN),
        .GAME_OVER => aud.playAudio(res.AUDIO_LOSE),
    }

    status = s;
    willTerm = true;
    termCount = ren.RENDER_TERM_COUNT;
}

fn pauseGame() void {
    aud.pauseSound();
    aud.playAudio(res.AUDIO_BUTTON1);

    ren.dim();

    const text = tps.createText("Paused", tps.WHITE);
    _ = ren.renderCenteredText(text, res.SCREEN_WIDTH / 2, res.SCREEN_HEIGHT / 2, 1);
    _ = c.SDL_RenderPresent(ren.renderer);
    tps.destroyText(text);

    var e: c.SDL_Event = undefined;
    var quit = false;
    while (!quit) {
        while (c.SDL_PollEvent(&e) != 0) {
            if (e.type == c.SDL_QUIT or e.type == c.SDL_KEYDOWN) {
                quit = true;
                break;
            }
        }
    }

    aud.resumeSound();
    aud.playAudio(res.AUDIO_BUTTON1);
}

fn arrowsToDirection(keyValue: c_int) ?tps.Direction {
    switch (keyValue) {
        c.SDLK_LEFT => return .LEFT,
        c.SDLK_RIGHT => return .RIGHT,
        c.SDLK_UP => return .UP,
        c.SDLK_DOWN => return .DOWN,
        else => return null,
    }
}

fn wasdToDirection(keyValue: c_int) ?tps.Direction {
    switch (keyValue) {
        c.SDLK_a => return .LEFT,
        c.SDLK_d => return .RIGHT,
        c.SDLK_w => return .UP,
        c.SDLK_s => return .DOWN,
        else => return null,
    }
}

fn generateEnemy(
    x: c_int,
    y: c_int,
    minLen: c_int,
    maxLen: c_int,
    minId: c_int,
    maxId: c_int,
    step: c_int,
) c_int {
    spriteSnake[@intCast(spritesCount)] = pl.createSnake(step, GAME_MONSTERS_TEAM, .COMPUTER);
    const snake = spriteSnake[@intCast(spritesCount)].?;
    spritesCount += 1;
    hasEnemy[@intCast(x)][@intCast(y)] = true;
    const vertical: bool = hlp.randInt(0, 1) == 1;
    var len: c_int = 1;

    if (vertical) {
        // just 3 casted aliaes
        const xx: usize = @intCast(x);
        const yy: usize = @intCast(y);
        const llen: usize = @intCast(len);

        while (hlp.inr(y + len, 0, res.m - 1) and mp.hasMap[xx][yy + llen] and
            map[xx][yy + llen].bp == .BLOCK_FLOOR and
            itemMap[xx][yy + llen].type == .ITEM_NONE and !hasEnemy[xx][yy + llen])
        {
            len += 1;
        }
    } else {
        // just 3 casted aliaes
        const xx: usize = @intCast(x);
        const yy: usize = @intCast(y);
        const llen: usize = @intCast(len);
        while (hlp.inr(x + len, 0, res.n - 1) and mp.hasMap[xx + llen][yy] and
            map[xx + llen][yy].bp == .BLOCK_FLOOR and
            itemMap[xx + llen][yy].type == .ITEM_NONE and !hasEnemy[xx + llen][yy])
        {
            len += 1;
        }
    }

    // NOTE: r.c. - since Zig can't shadow, and don't want to create new vars, just passing
    // @min() output directly into hlp.randInt below.
    len = hlp.randInt(@min(minLen, len), @min(maxLen, len));

    for (0..@intCast(len)) |i| {
        var xx: c_int = x;
        var yy: c_int = y;

        if (vertical) {
            yy += @intCast(i);
        } else {
            xx += @intCast(i);
        }

        hasEnemy[@intCast(xx)][@intCast(yy)] = true;
        xx *= res.UNIT;
        yy *= res.UNIT;
        yy += res.UNIT;
        xx += res.UNIT / 2;
        const spriteId: c_int = hlp.randInt(minId, maxId);
        appendSpriteToSnake(
            snake,
            spriteId,
            xx,
            yy,
            if (vertical) .DOWN else .RIGHT,
        );
    }
    return len;
}

fn getAvailablePos() tps.Point {
    var x: c_int = undefined;
    var y: c_int = undefined;

    while (true) {
        x = hlp.randInt(0, res.n - 1);
        y = hlp.randInt(0, res.m - 1);

        // r.c. - This code is different than the C version, the C one has undefined behavior.
        if (!hlp.inr(x, 1, res.n - 2) or !hlp.inr(y, 1, res.m - 2)) {
            // NOTE: Seems like a bug was caught in Zig.
            // Anytime x or y falls on the edge of the map we just pick a new random tuple.
            // Otherwise the code below can panic for example: xx - 1 panics when xx is a 0.
            continue;
        }

        const xx: usize = @intCast(x);
        const yy: usize = @intCast(y);

        // std.log.info("xx => {d}", .{xx});
        // std.log.info("yy => {d}", .{yy});

        const ha: c_int = @intFromBool(!mp.hasMap[xx - 1][yy]);
        const hb: c_int = @intFromBool(!mp.hasMap[xx + 1][yy]);
        const hc: c_int = @intFromBool(!mp.hasMap[xx][yy + 1]);
        const hd: c_int = @intFromBool(!mp.hasMap[xx][yy - 1]);

        const cond = !mp.hasMap[xx][yy] or map[xx][yy].bp != .BLOCK_FLOOR or
            itemMap[xx][yy].type != .ITEM_NONE or hasEnemy[xx][yy] or (ha + hb + hc + hd) >= 1;

        if (!cond) break;
    }

    return .{ .x = x, .y = y };
}

fn initEnemies(enemiesCount: c_int) void {
    hasEnemy = std.mem.zeroes([mp.MAP_SIZE][mp.MAP_SIZE]bool);

    // NOTE: r.c. - limit scope of i indexer.
    {
        var i: c_int = -2;
        while (i <= 2) : (i += 1) {
            var j: c_int = -2;
            while (j <= 2) : (j += 1) {
                const a: c_int = res.n / 2 + i;
                const b: c_int = res.m / 2 + j;
                hasEnemy[@intCast(a)][@intCast(b)] = true;
            }
        }
    }

    var i: usize = 0;
    while (i < enemiesCount) {
        const rand = hlp.randDouble() * GAME_MONSTERS_GEN_FACTOR;
        const pos = getAvailablePos();
        const x = pos.x;
        const y = pos.y;

        const minLen: c_int = 2;
        const maxLen: c_int = 4;
        var step: c_int = 1;

        var startId: c_int = res.SPRITE_TINY_ZOMBIE;
        var endId: c_int = res.SPRITE_TINY_ZOMBIE;

        // NOTE: r.c. - line below commented out in original.
        // double random = i * GAME_MONSTERS_GEN_FACTOR / enemiesCount;

        if (rand < 0.3) {
            startId = res.SPRITE_TINY_ZOMBIE;
            endId = res.SPRITE_SKELET;
        } else if (rand < 0.4) {
            startId = res.SPRITE_WOGOL;
            endId = res.SPRITE_CHROT;
            step = 2;
        } else if (rand < 0.5) {
            startId = res.SPRITE_ZOMBIE;
            endId = res.SPRITE_ICE_ZOMBIE;
        } else if (rand < 0.8) {
            startId = res.SPRITE_MUDDY;
            endId = res.SPRITE_SWAMPY;
        } else {
            startId = res.SPRITE_MASKED_ORC;
            endId = res.SPRITE_NECROMANCER;
        }

        i += @intCast(generateEnemy(
            x,
            y,
            minLen,
            maxLen,
            startId,
            endId,
            step,
        ));
    }

    // Adds bosses depending on bossSetting.
    for (0..@intCast(bossSetting)) |_| {
        const pos = getAvailablePos();
        _ = generateEnemy(
            pos.x,
            pos.y,
            1,
            1,
            res.SPRITE_BIG_ZOMBIE,
            res.SPRITE_BIG_DEMON,
            1,
        );
    }
}

// Put buff animation on snake

fn freezeSnake(snake: *pl.Snake, duration: c_int) void {
    if (snake.buffs[tps.BUFF_FROZEN] > 0) return;

    if (snake.buffs[tps.BUFF_DEFENCE] <= 0) {
        snake.buffs[tps.BUFF_FROZEN] += duration;
    }

    var dur: c_int = duration;
    var effect: ?*tps.Effect = null;
    if (snake.buffs[tps.BUFF_DEFENCE] > 0) {
        effect = @alignCast(@ptrCast(c.malloc(@sizeOf(tps.Effect))));
        tps.copyEffect(&res.effects[res.EFFECT_VANISH30], effect.?);
        dur = 30;
    }

    var p = snake.sprites.first;
    while (p != null) : (p = p.?.next) {
        const sprite: *spr.Sprite = @alignCast(@ptrCast(p.?.data));
        const ani = ren.createAndPushAnimation(
            &ren.animationsList[ren.RENDER_LIST_EFFECT_ID],
            &res.textures[res.RES_ICE],
            effect,
            .LOOP_ONCE,
            dur,
            sprite.x,
            sprite.y,
            c.SDL_FLIP_NONE,
            0,
            .AT_BOTTOM_CENTER,
        );
        ani.scaled = false;
        if (snake.buffs[tps.BUFF_DEFENCE] > 0) {
            continue;
        }
        ren.bindAnimationToSprite(ani, sprite, true);
    }
}

fn slowDownSnake(snake: *pl.Snake, duration: c_int) void {
    // Already slowed, so just exit function.
    if (snake.buffs[tps.BUFF_SLOWDOWN] > 0) return;

    // If we have no defense left, apply the slowdown buff.
    if (snake.buffs[tps.BUFF_DEFENCE] <= 0) {
        snake.buffs[tps.BUFF_SLOWDOWN] += duration;
    }

    var dur: c_int = duration;
    var effect: ?*tps.Effect = null;
    if (snake.buffs[tps.BUFF_DEFENCE] > 0) {
        effect = @alignCast(@ptrCast(c.malloc(@sizeOf(tps.Effect))));
        tps.copyEffect(&res.effects[res.EFFECT_VANISH30], effect.?);
        dur = 30;
    }

    var p = snake.sprites.first;
    while (p != null) : (p = p.?.next) {
        const sprite: *spr.Sprite = @alignCast(@ptrCast(p.?.data));
        const ani = ren.createAndPushAnimation(
            &ren.animationsList[ren.RENDER_LIST_EFFECT_ID],
            &res.textures[res.RES_SOLIDFX],
            effect,
            .LOOP_LIFESPAN,
            40,
            sprite.x,
            sprite.y,
            c.SDL_FLIP_NONE,
            0,
            .AT_BOTTOM_CENTER,
        );
        ani.lifeSpan = duration;
        ani.scaled = false;
        if (snake.buffs[tps.BUFF_DEFENCE] > 0) {
            continue;
        }
        ren.bindAnimationToSprite(ani, sprite, true);
    }
}

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
    if (snake.buffs[tps.BUFF_DEFENCE] > 0) return;
    snake.buffs[tps.BUFF_DEFENCE] += duration;

    var p = snake.sprites.first;
    while (p != null) : (p = p.?.next) {
        const sprite: *spr.Sprite = @alignCast(@ptrCast(p.?.data));
        shieldSprite(sprite, duration);
    }

    aud.playAudio(res.AUDIO_HOLY);
}

fn attackUpSprite(sprite: *spr.Sprite, duration: c_int) void {
    const ani = ren.createAndPushAnimation(
        &ren.animationsList[ren.RENDER_LIST_EFFECT_ID],
        &res.textures[res.RES_ATTACK_UP],
        null,
        .LOOP_LIFESPAN,
        ren.SPRITE_ANIMATION_DURATION,
        sprite.x,
        sprite.y,
        c.SDL_FLIP_NONE,
        0,
        .AT_BOTTOM_CENTER,
    );
    ren.bindAnimationToSprite(ani, sprite, true);
    ani.lifeSpan = duration;
}

fn attackUpSnake(snake: *pl.Snake, duration: c_int) void {
    if (snake.buffs[tps.BUFF_ATTACK] > 0) return;

    snake.buffs[tps.BUFF_ATTACK] += duration;

    var p = snake.sprites.first;
    while (p != null) : (p = p.?.next) {
        attackUpSprite(@alignCast(@ptrCast(p.?.data)), duration);
    }
}

fn takeHpMedcine(snake: *pl.Snake, delta: c_int, extra: bool) void {
    var p = snake.sprites.first;
    while (p != null) : (p = p.?.next) {
        const sprite: *spr.Sprite = @alignCast(@ptrCast(p.?.data));
        if (sprite.hp == sprite.totalHp and !extra) {
            continue;
        }

        var addHp: c_int = @intFromFloat(@as(f64, @floatFromInt(delta)) *
            @as(f64, @floatFromInt(sprite.totalHp)) / 100.0);

        if (!extra) {
            addHp = @max(0, @min(sprite.totalHp - sprite.hp, addHp));
        }
        sprite.hp += addHp;

        const ani = ren.createAndPushAnimation(
            &ren.animationsList[ren.RENDER_LIST_EFFECT_ID],
            &res.textures[res.RES_HP_MED],
            null,
            .LOOP_ONCE,
            ren.SPRITE_ANIMATION_DURATION,
            sprite.x,
            sprite.y,
            c.SDL_FLIP_NONE,
            0,
            .AT_BOTTOM_CENTER,
        );

        ren.bindAnimationToSprite(ani, sprite, false);
    }
}

fn takeWeapon(snake: *pl.Snake, weaponItem: *tps.Item) bool {
    const weapon = &wp.weapons[@intCast(weaponItem.id)];
    var taken = false;

    var p = snake.sprites.first;
    while (p != null) : (p = p.?.next) {
        const sprite: *spr.Sprite = @alignCast(@ptrCast(p.?.data));
        if (sprite.ani.origin == res.commonSprites[@intCast(weaponItem.belong)].ani.origin and
            sprite.weapon == res.commonSprites[@intCast(weaponItem.belong)].weapon)
        {
            sprite.weapon = weapon;
            var ani = ren.createAndPushAnimation(
                &ren.animationsList[ren.RENDER_LIST_EFFECT_ID],
                weaponItem.ani.origin,
                null,
                .LOOP_INFI,
                3,
                sprite.x,
                sprite.y,
                c.SDL_FLIP_NONE,
                0,
                .AT_BOTTOM_CENTER,
            );
            ren.bindAnimationToSprite(ani, sprite, true);

            sprite.hp += @intFromFloat((@as(f64, GAME_HP_MEDICINE_EXTRA_DELTA) / 100.0) * @as(f64, @floatFromInt(sprite.totalHp)) * 5.0);

            ani = ren.createAndPushAnimation(
                &ren.animationsList[ren.RENDER_LIST_EFFECT_ID],
                &res.textures[res.RES_HP_MED],
                null,
                .LOOP_ONCE,
                ren.SPRITE_ANIMATION_DURATION,
                0,
                0,
                c.SDL_FLIP_NONE,
                0,
                .AT_BOTTOM_CENTER,
            );
            ren.bindAnimationToSprite(ani, sprite, true);
            taken = true;
            break;
        }
    }
    return taken;
}

fn dropItemNearSprite(sprite: *spr.Sprite, itemType: tps.ItemType) void {
    var dx: c_int = -1;
    while (dx <= 1) : (dx += 1) {
        var dy: c_int = -1;
        while (dy <= 1) : (dy += 1) {
            const x = @divTrunc(sprite.x, res.UNIT) + dx;
            const y = @divTrunc(sprite.y, res.UNIT) + dy;

            if (hlp.inr(x, 0, res.n - 1) and
                hlp.inr(y, 0, res.m - 1) and
                mp.hasMap[@intCast(x)][@intCast(y)] and itemMap[@intCast(x)][@intCast(y)].type == .ITEM_NONE)
            {
                generateItem(x, y, itemType);
            }
            return;
        }
    }
}

// Initialize and deinitialize game and snake.

fn generateHeroItemAllMap() void {
    var x: c_int = undefined;
    var y: c_int = undefined;

    // Converted from do-while to while(true) w/ negated condition and break
    while (true) {
        x = hlp.randInt(1, res.n - 2);
        y = hlp.randInt(1, res.m - 2);

        // r.c. - This code is different than the C version, the C one has undefined behavior.
        if (!hlp.inr(x, 1, res.n - 2) or !hlp.inr(y, 1, res.m - 2)) {
            // NOTE: Seems like a bug was caught in Zig.
            // Anytime x or y falls on the edge of the map we just pick a new random tuple.
            // Otherwise the code below can panic for example: xx - 1 panics when xx is a 0.
            continue;
        }

        const xx: usize = @intCast(x);
        const yy: usize = @intCast(y);

        const ha: c_int = @intFromBool(!mp.hasMap[xx - 1][yy]);
        const hb: c_int = @intFromBool(!mp.hasMap[xx + 1][yy]);
        const hc: c_int = @intFromBool(!mp.hasMap[xx][yy + 1]);
        const hd: c_int = @intFromBool(!mp.hasMap[xx][yy - 1]);

        const cond = !mp.hasMap[xx][yy] or
            map[xx][yy].bp != .BLOCK_FLOOR or
            itemMap[xx][yy].type != .ITEM_NONE or
            ha + hb + hc + hd >= 1;

        if (!cond) break;
    }

    generateHeroItem(x, y);
}

fn clearItemMap() void {
    for (0..res.n) |i| {
        for (0..res.m) |j| {
            itemMap[i][j].type = .ITEM_NONE;
        }
    }
}

fn initItemMap(incomingHerosCount: c_int, incomingFlasksCount: c_int) void {
    var hc = incomingHerosCount;
    var fc = incomingFlasksCount;

    var x: c_int = undefined;
    var y: c_int = undefined;

    while (hc > 0) : (hc -= 1) {
        generateHeroItemAllMap();
        herosCount += 1;
    }

    while (fc > 0) : (fc -= 1) {
        // Converted from do-while to while w/negated break
        while (true) {
            x = hlp.randInt(0, res.n - 1);
            y = hlp.randInt(0, res.m - 1);

            const xx: usize = @intCast(x);
            const yy: usize = @intCast(y);
            const cond = !mp.hasMap[xx][yy] or
                map[xx][yy].bp != .BLOCK_FLOOR or
                itemMap[xx][yy].type != .ITEM_NONE;

            if (!cond) break;
        }

        generateItem(x, y, .ITEM_HP_MEDICINE);
        flasksCount += 1;
    }
}

fn initGame(localPlayers: c_int, remotePlayers: c_int, localFirst: bool) void {
    aud.randomBgm();
    status = .STAGE_CLEAR;
    termCount = 0;
    willTerm = false;
    spritesCount = 0;
    playersCount = 0;
    flasksCount = 0;
    herosCount = 0;
    ren.initRenderer();
    ren.initCountDownBar();

    // create default hero at (w/2, h/2) (as well push ani)
    for (0..(@as(usize, @intCast(localPlayers)) + @as(usize, @intCast(remotePlayers)))) |i| {
        var playerType: pl.PlayerType = .LOCAL;
        if (localFirst) {
            playerType = if (i < localPlayers) .LOCAL else .REMOTE;
        } else {
            playerType = if (i < remotePlayers) .REMOTE else .LOCAL;
        }
        initPlayer(playerType);
        shieldSnake(spriteSnake[i].?, 300);
    }
    ren.initInfo();
    // create map
    mp.initRandomMap(0.7, 7, GAME_TRAP_RATE);

    clearItemMap();

    // create enemies
    initEnemies(spritesSetting);
    mp.pushMapToRender();
    bullets = tps.createLinkList();

    std.log.info("initGame finished...", .{});
}

fn destroyGame(currentStatus: GameStatus) void {
    while (spritesCount > 0) {
        spritesCount -= 1;
        destroySnake(spriteSnake[@intCast(spritesCount)].?);
        spriteSnake[@intCast(spritesCount)] = null;
    }

    for (0..ren.ANIMATION_LINK_LIST_NUM) |i| {
        tps.destroyAnimationsByLinkList(&ren.animationsList[i]);
    }

    var p = bullets.?.first;
    while (p != null) : (p = p.?.next) {
        blt.destroyBullet(@alignCast(@ptrCast(p.?.data)));
        p.?.data = null;
    }

    tps.destroyLinkList(bullets.?);
    bullets = null;

    ren.blackout();

    var msg: [*:0]const u8 = "Game Over";
    if (currentStatus == .STAGE_CLEAR) {
        msg = "Stage Clear";
    }

    const text = tps.createText(msg, tps.WHITE);
    _ = ren.renderCenteredText(text, res.SCREEN_WIDTH / 2, res.SCREEN_HEIGHT / 2, 2);
    tps.destroyText(text);
    _ = c.SDL_RenderPresent(ren.renderer);
    std.time.sleep(ren.RENDER_GAMEOVER_DURATION * std.time.ns_per_s);
    ren.clearRenderer();
}

pub fn destroySnake(snake: *pl.Snake) void {
    if (bullets) |bu| {
        var p = bu.first;
        while (p != null) : (p = p.?.next) {
            const bullet: *blt.Bullet = @alignCast(@ptrCast(p.?.data.?));
            if (bullet.owner == snake) {
                bullet.owner = null;
            }
        }
    }

    var p = snake.sprites.first;
    while (p != null) : (p = p.?.next) {
        const sprite: *spr.Sprite = @alignCast(@ptrCast(p.?.data.?));
        c.free(sprite);
        p.?.data = null;
    }

    tps.destroyLinkList(snake.sprites);
    //snake.sprites = null; // currently it's non-nullable.
    tps.destroyScore(snake.score);
    //snake.score = null; // currently it's non-nullable.
    std.log.info("destroySnake: Freeing snake at address: {*}", .{snake});
    c.free(snake);
}

///  Helper function to determine whehter a snake is a player
inline fn isPlayer(snake: *pl.Snake) bool {
    for (0..@intCast(playersCount)) |i| {
        if (snake == spriteSnake[i]) return true;
    }
    return false;
}

//  Verdict if a sprite crushes on other objects

pub fn crushVerdict(sprite: *spr.Sprite, loose: bool, useAnimationBox: bool) bool {
    const x = sprite.x;
    const y = sprite.y;

    const box: c.SDL_Rect = if (useAnimationBox) hlp.getSpriteAnimationBox(sprite) else hlp.getSpriteFeetBox(sprite);
    var block = box;

    // If the sprite is out of the map, then consider it as crushed
    if (hlp.inr(@divTrunc(x, res.UNIT), 0, res.n - 1) and
        hlp.inr(@divTrunc(y, res.UNIT), 0, res.m - 1))
    {
        //nothing to do
    } else {
        return true;
    }

    // Loop over the cells nearby the sprite to know better if it falls out of map
    var dx: c_int = -1;
    while (dx <= 1) : (dx += 1) {
        var dy: c_int = -1;
        while (dy <= 1) : (dy += 1) {
            const xx: c_int = @divTrunc(x, res.UNIT) + dx;
            const yy: c_int = @divTrunc(y, res.UNIT) + dy;
            if (hlp.inr(xx, 0, res.n - 1) and hlp.inr(yy, 0, res.m - 1)) {
                block = hlp.getMapRect(@intCast(xx), @intCast(yy));
                if (hlp.RectRectCross(&box, &block) and !mp.hasMap[@intCast(xx)][@intCast(yy)]) {
                    return true;
                }
            }
        }
    }

    // If it has crushed on other sprites
    for (0..@intCast(spritesCount)) |i| {
        var self = false;
        var p = spriteSnake[i].?.sprites.first;
        while (p != null) : (p = p.?.next) {
            const other: *spr.Sprite = @alignCast(@ptrCast(p.?.data));
            if (other != sprite) {
                const otherBox = if (useAnimationBox) hlp.getSpriteAnimationBox(other) else hlp.getSpriteFeetBox(other);
                if (hlp.RectRectCross(&box, &otherBox)) {
                    if ((self and loose) or (p.?.prev != null and p.?.prev.?.data == @as(?*anyopaque, @ptrCast(sprite)))) {
                        // Do nothing.
                    } else {
                        return true;
                    }
                }
            } else {
                self = true;
            }
        }
    }
    return false;
}

fn dropItem(sprite: *spr.Sprite) void {
    const random = hlp.randDouble() * sprite.dropRate * GAME_LUCKY;
    // #ifdef DBG
    // // printf("%lf\n", random);
    // #endif
    if (random < GAME_DROPOUT_YELLOW_FLASKS) {
        dropItemNearSprite(sprite, .ITEM_HP_EXTRA_MEDICINE);
    } else if (random > GAME_DROPOUT_WEAPONS) {
        dropItemNearSprite(sprite, .ITEM_WEAPON);
    }
}

fn invokeWeaponBuff(src: ?*pl.Snake, weapon: *wp.Weapon, dest: *pl.Snake, damage: c_int) void {
    _ = damage;

    var rand: f64 = undefined;
    for (tps.BUFF_BEGIN..tps.BUFF_END) |i| {
        rand = hlp.randDouble();
        if (src != null and src.?.team == GAME_MONSTERS_TEAM) {
            rand *= GAME_MONSTERS_WEAPON_BUFF_ADJUST;
        }
        if (rand < weapon.effects[i].chance) {
            switch (i) {
                tps.BUFF_FROZEN => freezeSnake(dest, weapon.effects[i].duration),
                tps.BUFF_SLOWDOWN => slowDownSnake(dest, weapon.effects[i].duration),
                tps.BUFF_DEFENCE => {
                    if (src) |s| {
                        shieldSnake(s, weapon.effects[i].duration);
                    }
                },
                tps.BUFF_ATTACK => {
                    if (src) |s| {
                        attackUpSnake(s, weapon.effects[i].duration);
                    }
                },
                else => {},
            }
        }
    }
}

/// dealDamage src is optionally null from some callers.
fn dealDamage(src: ?*pl.Snake, dest: *pl.Snake, target: *spr.Sprite, damage: c_int) void {
    var calcDamage: f64 = @floatFromInt(damage);

    if (dest.buffs[tps.BUFF_FROZEN] > 0) {
        calcDamage *= GAME_FROZEN_DAMAGE_K;
    }

    if (src != null and src.? != spriteSnake[GAME_MONSTERS_TEAM]) {
        if (src.?.buffs[tps.BUFF_ATTACK] > 0) calcDamage *= GAME_BUFF_ATTACK_K;
    }

    if (dest != spriteSnake[GAME_MONSTERS_TEAM]) {
        if (dest.buffs[tps.BUFF_DEFENCE] > 0) calcDamage /= GAME_BUFF_DEFENSE_K;
    }

    target.hp -= @intFromFloat(calcDamage);

    if (src) |s| {
        s.score.damage += @intFromFloat(calcDamage);
        if (target.hp <= 0) s.score.killed += 1;
    }

    dest.score.stand += damage;
}

fn makeSnakeCross(snake: *pl.Snake) bool {
    if (snake.sprites.first == null) return false;

    // Trap and Item ( everything related to block ) verdict
    for (0..(res.SCREEN_WIDTH / res.UNIT)) |i| {
        for (0..(res.SCREEN_HEIGHT / res.UNIT)) |j| {
            if (mp.hasMap[i][j]) {
                const block: c.SDL_Rect = .{
                    .x = @as(c_int, @intCast(i)) * res.UNIT,
                    .y = @as(c_int, @intCast(j)) * res.UNIT,
                    .w = res.UNIT,
                    .h = res.UNIT,
                };
                if (map[i][j].bp == .BLOCK_TRAP and map[i][j].enable) {
                    var p = snake.sprites.first;
                    while (p != null) : (p = p.?.next) {
                        const sprite: *spr.Sprite = @alignCast(@ptrCast(p.?.data));
                        const spriteRect = hlp.getSpriteFeetBox(sprite);
                        if (hlp.RectRectCross(&spriteRect, &block)) {
                            dealDamage(null, snake, sprite, spikeDamage);
                        }
                    }
                }
                if (isPlayer(snake)) {
                    const headBox = hlp.getSpriteFeetBox(@alignCast(@ptrCast(snake.sprites.first.?.data)));
                    if (itemMap[i][j].type != .ITEM_NONE) {
                        if (hlp.RectRectCross(&headBox, &block)) {
                            var taken = true;
                            const ani = itemMap[i][j].ani;
                            if (itemMap[i][j].type == .ITEM_HERO) {
                                aud.playAudio(res.AUDIO_COIN);
                                appendSpriteToSnake(snake, itemMap[i][j].id, 0, 0, .RIGHT);
                                herosCount -= 1;
                                tps.removeAnimationFromLinkList(&ren.animationsList[ren.RENDER_LIST_SPRITE_ID], ani);
                            } else if (itemMap[i][j].type == .ITEM_HP_MEDICINE or
                                itemMap[i][j].type == .ITEM_HP_EXTRA_MEDICINE)
                            {
                                aud.playAudio(res.AUDIO_MED);
                                takeHpMedcine(snake, GAME_HP_MEDICINE_DELTA, itemMap[i][j].type == .ITEM_HP_EXTRA_MEDICINE);
                                flasksCount -= @intFromBool(itemMap[i][j].type == .ITEM_HP_MEDICINE);

                                tps.removeAnimationFromLinkList(&ren.animationsList[ren.RENDER_LIST_MAP_ITEMS_ID], ani);
                            } else if (itemMap[i][j].type == .ITEM_WEAPON) {
                                taken = takeWeapon(snake, &itemMap[i][j]);
                                if (taken) {
                                    aud.playAudio(res.AUDIO_MED);
                                    tps.removeAnimationFromLinkList(&ren.animationsList[ren.RENDER_LIST_MAP_ITEMS_ID], ani);
                                }
                            }
                            if (taken) itemMap[i][j].type = .ITEM_NONE;
                        }
                    }
                }
            }
        }
    }
    {
        // Created inner scope to limit p lifetime.
        // Death verdict, create death ani
        var p = snake.sprites.first;
        while (p != null) : (p = p.?.next) {
            const sprite: *spr.Sprite = @alignCast(@ptrCast(p.?.data));
            if (sprite.hp <= 0) {
                aud.playAudio(res.AUDIO_HUMAN_DEATH);

                // WARNING: Dangerous here too, this is legit pointer arithmetic
                // as it's fully dependant on the textures array layout.

                // r.c. - based on textures array, a player should be on the run animation
                // the immediate texture higher in the array is the "hit" texture for that player.
                // So it goes from: {character-type}_run_anim -> {character-type}_hit_anim
                // NOTE: Only some characters have the _hit_anim
                var deathPtr: usize = @intFromPtr(sprite.ani.origin);
                std.log.debug("Death dbg: {s}, b4 ptr: {*}", .{ std.mem.sliceTo(&sprite.ani.origin.dbgName, 0), sprite.ani.origin });

                if (isPlayer(snake)) deathPtr += (@sizeOf(tps.Texture) * 1);

                const possiblyNewTexture = @as(*tps.Texture, @ptrFromInt(deathPtr));
                std.log.debug("Death dbg: {s}, aft ptr: {*}", .{ std.mem.sliceTo(&possiblyNewTexture.dbgName, 0), possiblyNewTexture });

                dropItem(sprite);

                _ = ren.createAndPushAnimation(
                    &ren.animationsList[ren.RENDER_LIST_DEATH_ID],
                    &res.textures[res.RES_SKULL],
                    null,
                    .LOOP_INFI,
                    1,
                    sprite.x + hlp.randInt(-mp.MAP_SKULL_SPILL_RANGE, mp.MAP_SKULL_SPILL_RANGE),
                    sprite.y + hlp.randInt(-mp.MAP_SKULL_SPILL_RANGE, mp.MAP_SKULL_SPILL_RANGE),
                    if (sprite.face == .LEFT) c.SDL_FLIP_NONE else c.SDL_FLIP_HORIZONTAL,
                    0,
                    .AT_BOTTOM_CENTER,
                );

                _ = ren.createAndPushAnimation(
                    &ren.animationsList[ren.RENDER_LIST_DEATH_ID],
                    @ptrFromInt(deathPtr),
                    &res.effects[res.EFFECT_DEATH],
                    .LOOP_ONCE,
                    ren.SPRITE_ANIMATION_DURATION,
                    sprite.x,
                    sprite.y,
                    if (sprite.face == .RIGHT) c.SDL_FLIP_NONE else c.SDL_FLIP_HORIZONTAL,
                    0,
                    .AT_BOTTOM_CENTER,
                );

                // TOO BLOODY - commented out in the original C project.
                _ = ren.createAndPushAnimation(
                    &ren.animationsList[ren.RENDER_LIST_MAP_SPECIAL_ID],
                    &res.textures[@intCast(hlp.randInt(res.RES_BLOOD1, res.RES_BLOOD4))],
                    null,
                    .LOOP_INFI,
                    ren.SPRITE_ANIMATION_DURATION,
                    sprite.x +
                        hlp.randInt(-mp.MAP_BLOOD_SPILL_RANGE, mp.MAP_BLOOD_SPILL_RANGE),
                    sprite.y +
                        hlp.randInt(-mp.MAP_BLOOD_SPILL_RANGE, mp.MAP_BLOOD_SPILL_RANGE),
                    if (sprite.face == .RIGHT)
                        c.SDL_FLIP_NONE
                    else
                        c.SDL_FLIP_HORIZONTAL,
                    0,
                    .AT_BOTTOM_CENTER,
                );

                ren.clearBindInAnimationsList(sprite, ren.RENDER_LIST_EFFECT_ID);
                ren.clearBindInAnimationsList(sprite, ren.RENDER_LIST_SPRITE_ID);
                tps.removeAnimationFromLinkList(&ren.animationsList[ren.RENDER_LIST_SPRITE_ID], sprite.ani);
                //sprite.ani = null;
                snake.num -= 1;
            }
        }
    }

    // Remove sprites where hp is 0 and shift over positions in Linked List.
    {
        // r.c. - Introduced scope to limit p lifetime.
        var p = snake.sprites.first;
        var nxt: ?*adt.GenericNode = undefined;
        while (p != null) : (p = nxt) {
            // r.c. - NOTE: Code is slightly different from original as a double-free was occuring.
            // This code ensures that the a fresh const possibleSpriteToDelete identifier
            // is used so that it doesn't get overwritten in the inner loop.
            // We need to ensure we only delete one sprite when the hp <= 0.
            const possibleSpriteToDelete: *spr.Sprite = @alignCast(@ptrCast(p.?.data));
            nxt = p.?.next;
            if (possibleSpriteToDelete.hp <= 0) {
                var q = snake.sprites.last;
                while (q != p) : (q = q.?.prev) {
                    const prevSprite: *spr.Sprite = @alignCast(@ptrCast(q.?.prev.?.data));
                    const currSprite: *spr.Sprite = @alignCast(@ptrCast(q.?.data));
                    currSprite.direction = prevSprite.direction;
                    currSprite.face = prevSprite.face;
                    currSprite.posBuffer = prevSprite.posBuffer;
                    currSprite.x = prevSprite.x;
                    currSprite.y = prevSprite.y;
                }
                tps.removeLinkNode(snake.sprites, p.?);
                // NOTE: Double free was occuring here.
                c.free(possibleSpriteToDelete);
            }
        }
    }

    if (snake.sprites.first == null) {
        return false;
    }
    const snakeHead: *spr.Sprite = @alignCast(@ptrCast(snake.sprites.first.?.data));
    const die = crushVerdict(snakeHead, !isPlayer(snake), false);
    if (die) {
        var p = snake.sprites.first;
        while (p != null) : (p = p.?.next) {
            const sprite: *spr.Sprite = @alignCast(@ptrCast(p.?.data));
            sprite.hp = 0;
        }
    }

    return die;
}

/// makeBulletCross is the bullet's collission detection.
/// Does it hit a player? Or does it hit the map boundaries?
/// Upon a hit, make it explode and play the relevant sound fx.
fn makeBulletCross(bullet: *blt.Bullet) bool {
    const weapon = bullet.parent;
    var hit = false;

    const bulletScale: f64 = if (bullet.ani.scaled) ren.SCALE_FACTOR else 1.0;
    const width: c_int = @min(bullet.ani.origin.width, bullet.ani.origin.height) *
        @as(c_int, @intFromFloat(bulletScale * 0.8));

    const bulletBox: c.SDL_Rect = .{
        .x = bullet.x - @divTrunc(width, 2),
        .y = bullet.y - @divTrunc(width, 2),
        .w = width,
        .h = width,
    };

    if (!mp.hasMap[@intCast(@divTrunc(bullet.x, res.UNIT))][@intCast(@divTrunc(bullet.y, res.UNIT))]) {
        const ani: *tps.Animation = @alignCast(@ptrCast(c.malloc(@sizeOf(tps.Animation))));
        tps.copyAnimation(weapon.deathAni.?, ani);
        ani.x = bullet.x;
        ani.y = bullet.y;
        ren.pushAnimationToRender(ren.RENDER_LIST_EFFECT_ID, ani);
        hit = true;
    }
    if (!hit) {
        for (0..@intCast(spritesCount)) |i| {
            if (bullet.team != spriteSnake[i].?.team) {
                var p = spriteSnake[i].?.sprites.first;
                while (p != null) : (p = p.?.next) {
                    const target: *spr.Sprite = @alignCast(@ptrCast(p.?.data));
                    const box = hlp.getSpriteBoundBox(target);
                    if (hlp.RectRectCross(&box, &bulletBox)) {
                        const ani: *tps.Animation = @alignCast(@ptrCast(c.malloc(@sizeOf(tps.Animation))));
                        tps.copyAnimation(weapon.deathAni.?, ani);
                        ani.x = bullet.x;
                        ani.y = bullet.y;
                        ren.pushAnimationToRender(ren.RENDER_LIST_EFFECT_ID, ani);
                        hit = true;
                        if (weapon.wp == .WEAPON_GUN_POINT or
                            weapon.wp == .WEAPON_GUN_POINT_MULTI)
                        {
                            dealDamage(
                                bullet.owner,
                                spriteSnake[i].?,
                                target,
                                weapon.damage,
                            );

                            invokeWeaponBuff(
                                bullet.owner,
                                weapon,
                                spriteSnake[i].?,
                                weapon.damage,
                            );
                            return hit;
                        }
                        break;
                    }
                }
            }
        }
    }
    if (hit) {
        aud.playAudio(@intCast(weapon.deathAudio));
        for (0..@intCast(spritesCount)) |i| {
            if (bullet.team != spriteSnake[i].?.team) {
                var p = spriteSnake[i].?.sprites.first;
                while (p != null) : (p = p.?.next) {
                    const target: *spr.Sprite = @alignCast(@ptrCast(p.?.data));
                    if (hlp.distance(
                        .{ .x = target.x, .y = target.y },
                        .{ .x = bullet.x, .y = bullet.y },
                    ) <= @as(f64, @floatFromInt(weapon.effectRange))) {
                        dealDamage(
                            bullet.owner,
                            spriteSnake[i].?,
                            target,
                            weapon.damage,
                        );
                        invokeWeaponBuff(
                            bullet.owner,
                            weapon,
                            spriteSnake[i].?,
                            weapon.damage,
                        );
                    }
                }
            }
        }
    }
    return hit;
}

fn makeCross() void {
    for (0..@intCast(spritesCount)) |i| {
        _ = makeSnakeCross(spriteSnake[i].?);
    }

    var p = bullets.?.first;
    var nxt: ?*adt.GenericNode = null;
    while (p != null) : (p = nxt) {
        nxt = p.?.next;
        const bullet: *blt.Bullet = @ptrCast(@alignCast(p.?.data));
        // If bullet crossed paths with something and a hit was registered
        // then remove the bullet.
        if (makeBulletCross(bullet)) {
            tps.removeAnimationFromLinkList(
                &ren.animationsList[ren.RENDER_LIST_EFFECT_ID],
                bullet.ani,
            );
            tps.removeLinkNode(bullets.?, p.?);
        }
    }
}

pub fn moveSprite(sprite: *spr.Sprite, step: c_int) void {
    const dir = sprite.direction;

    switch (dir) {
        .LEFT => sprite.x -= step,
        .RIGHT => sprite.x += step,
        .UP => sprite.y -= step,
        .DOWN => sprite.y += step,
    }
}

fn moveSnake(snake: *pl.Snake) void {
    if (snake.buffs[tps.BUFF_FROZEN] > 0) return;

    var step = snake.moveStep;
    if (snake.buffs[tps.BUFF_SLOWDOWN] > 0) {
        step = @max(@divTrunc(step, 2), 1);
    }

    var p = snake.sprites.first;
    while (p != null) : (p = p.?.next) {
        const sprite: *spr.Sprite = @ptrCast(@alignCast(p.?.data));

        for (0..@intCast(step)) |_| {
            const b = &sprite.posBuffer;
            var firstSlot = b.buffer[0];

            while (b.size > 0 and sprite.x == firstSlot.x and sprite.y == firstSlot.y) {
                tps.changeSpriteDirection(p.?, firstSlot.direction);
                b.size -= 1;
                for (0..@intCast(b.size)) |i| {
                    b.buffer[i] = b.buffer[i + 1];
                }
                firstSlot = b.buffer[0];
            }
            moveSprite(sprite, 1);
        }
    }
}

fn handleLocalKeypress() bool {
    // Static var in Zig.
    const S = struct {
        var e: c.SDL_Event = undefined;
    };

    var quit = false;
    while (c.SDL_PollEvent(&S.e) != 0) {
        if (S.e.type == c.SDL_QUIT) {
            quit = true;
            setTerm(.GAME_OVER);
        } else if (S.e.type == c.SDL_KEYDOWN) {
            const keyValue = S.e.key.keysym.sym;
            if (keyValue == c.SDLK_ESCAPE) {
                pauseGame();
            }

            var id: c_int = 0;
            while (id <= 1 and id < playersCount) : (id += 1) {
                const player = spriteSnake[@intCast(id)].?;
                // BUG: for player 0, why isn't .LOCAL condition passing????
                if (player.playerType == .LOCAL) {
                    if (player.buffs[tps.BUFF_FROZEN] == 0 and player.sprites.first != null) {
                        const direction = if (id == 0) arrowsToDirection(keyValue) else wasdToDirection(keyValue);
                        if (direction) |dir| {
                            //sendPlayerMovePacket(id, direction); // TODO for networking.
                            tps.changeSpriteDirection(player.sprites.first.?, dir);
                        }
                    }
                }
            }
        }
    }

    return quit;
}

fn gameLoop() GameStatus {
    var quit = false;
    var throttler = th.Throttler.init();
    //var lastTicks: u32 = 0;

    while (!quit) {
        if (throttler.shouldWait()) {
            continue;
        }
        // // Get ticks
        // const newTicks = c.SDL_GetTicks();
        // // Get ticks from last frame and compare with framerate
        // if (newTicks - lastTicks < 17) {
        //     c.SDL_Delay(17 - (newTicks - lastTicks));
        //     continue;
        // }

        quit = handleLocalKeypress();
        // if (quit) sendGameOverPacket(3);
        // if (lanClientSocket != NULL) handleLanKeypress();

        updateMap();

        for (0..@intCast(spritesCount)) |i| {
            if (spriteSnake[i].?.sprites.first == null) {
                continue; // some snakes killed by before but not clean up yet
            }
            if (i >= playersCount and ren.renderFrames % ai.AI_DECIDE_RATE == 0)
                ai.AiInput(spriteSnake[i].?);
            moveSnake(spriteSnake[i].?);
            makeSnakeAttack(spriteSnake[i].?);
        }

        // Move bullets.
        if (bullets) |b| {
            var p = b.first;
            while (p != null) : (p = p.?.next) {
                blt.moveBullet(@ptrCast(@alignCast(p.?.data)));
            }
        }

        if (ren.renderFrames % GAME_MAP_RELOAD_PERIOD == 0) {
            initItemMap(
                herosSetting - herosCount,
                flasksSetting - flasksCount,
            );
        }

        // Frozen behavior.
        for (0..@intCast(spritesCount)) |i| {
            ren.updateAnimationOfSnake(spriteSnake[i].?);
            if (spriteSnake[i].?.buffs[tps.BUFF_FROZEN] > 0) {
                var p = spriteSnake[i].?.sprites.first;
                while (p != null) : (p = p.?.next) {
                    const sprite: *spr.Sprite = @alignCast(@ptrCast(p.?.data));
                    sprite.ani.currentFrame -= 1;
                }
            }
        }

        makeCross();
        ren.render();
        updateBuffDuration();

        {
            // Cull snakes that have no more soldiers.
            var i: usize = @intCast(playersCount);
            while (i < spritesCount) : (i += 1) {
                if (spriteSnake[i].?.num == 0) {
                    destroySnake(spriteSnake[i].?);
                    spriteSnake[i] = null;
                    var j = i;
                    // All snakes after this one being removed, shift them left by one spot.
                    // This is supposed to eliminate 'null' holes in the spriteSnake array.
                    while ((j + 1) < spritesCount) : (j += 1) {
                        spriteSnake[j] = spriteSnake[j + 1];
                    }
                    spriteSnake[@intCast(spritesCount)] = null;
                    spritesCount -= 1;
                }
            }
        }

        if (willTerm) {
            termCount -= 1;
            if (termCount <= 0) {
                break;
            }
        } else {
            var alivePlayer: c_int = -1;
            for (0..@intCast(playersCount)) |i| {
                if (spriteSnake[i].?.sprites.first == null) {
                    setTerm(.GAME_OVER);
                    //sendGameOverPacket(alivePlayer);
                    break;
                } else {
                    alivePlayer = @intCast(i);
                }
            }
            if (isWin()) {
                setTerm(.STAGE_CLEAR);
            }
        }

        // Update the ticks
        //lastTicks = newTicks;
        throttler.tick();
        fps = throttler.frameRate();
    }

    return status;
}
