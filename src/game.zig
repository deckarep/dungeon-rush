const std = @import("std");
const stdout = std.io.getStdOut().writer();

const c = @import("c_headers.zig").c;
const rand = @import("std").rand;
const meta = @import("std").meta;

const types = @import("types.zig");
const audio = @import("audio.zig");
const render = @import("render.zig");
const map = @import("map.zig");

const MOVE_STEP: c_int = 2;

// Extern but not sure if this should stay or go.
extern var renderer: *c.SDL_Renderer;

// Extern.
pub extern var animationsList: [c.ANIMATION_LINK_LIST_NUM]c.LinkList;

// Extern for now.
pub extern var status: c_int;
pub extern var termCount: c_int;
pub extern var willTerm: bool;

pub extern var spriteSnake: [c.SPRITES_MAX_NUM]?*c.Snake;
pub extern var bullets: ?*c.LinkList;
pub extern var GAME_WIN_NUM: c_int;
pub extern var gameLevel: c_int;
pub extern var stage: c_int;
pub extern var spritesCount: c_int;
pub extern var playersCount: c_int;
pub extern var flasksCount: c_int;
pub extern var herosCount: c_int;
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
    const levelFloat: f64 = @floatFromInt(level);
    const stageFloat: f64 = @floatFromInt(stage);

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
    AI_LOCK_LIMIT = @max(1, 7 - levelFloat * 2 - stageFloat / 2);
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
    var scores: [*c][*c]c.Score = @ptrCast(@alignCast(c.malloc(@sizeOf([*c]c.Score) * @as(usize, @intCast(localPlayers)))));

    var i: usize = 0;
    while (i < localPlayers) : (i += 1) {
        scores[i] = types.createScore();
    }

    var myStatus: c_int = 0;
    stage = 0;

    while (true) {
        initGame(localPlayers, remotePlayers, localFirst);
        setLevel(gameLevel);
        myStatus = c.gameLoop();
        var j: usize = 0;
        while (j < localPlayers) : (j += 1) {
            if (spriteSnake[j]) |someSnek| {
                types.addScore(scores[j], someSnek.*.score);
            }
        }
        destroyGame(status);
        stage += 1;

        // Quit to previous screen.
        if (myStatus != 0) {
            status = myStatus;
            break;
        }
    }

    return scores;
}

pub extern const WHITE: c.SDL_Color;
fn destroyGame(arg_status: c_int) void {
    while (spritesCount != 0) {
        spritesCount -= 1;
        const sc: usize = @intCast(spritesCount);
        c.destroySnake(spriteSnake[sc]);
        spriteSnake[sc] = null;
    }

    var i: usize = 0;
    while (i < c.ANIMATION_LINK_LIST_NUM) : (i += 1) {
        types.destroyAnimationsByLinkList(&animationsList[i]);
    }

    if (bullets) |someBullets| {
        var p: ?*c.LinkNode = someBullets.*.head;
        while (p) |someP| {
            const b: *c.Bullet = @ptrCast(@alignCast(someP.*.element));
            c.destroyBullet(b);
            someP.*.element = null;
            p = someP.*.nxt;
        }
        types.destroyLinkList(someBullets);
    }

    bullets = null;

    render.blackout();

    var msg: [*]const u8 = undefined;
    if (arg_status == 0) {
        msg = "Stage Clear";
    } else {
        msg = "Game Over";
    }

    const text: *c.Text = c.createText(msg, WHITE);
    _ = render.renderCenteredText(text, c.SCREEN_WIDTH / 2, c.SCREEN_HEIGHT / 2, 2);
    types.destroyText(text);

    // UMMM, where the hell is this extern: renderer coming from??
    // Well, I added an extern up top...in this file but not entirely sure if this is correct.
    _ = c.SDL_RenderPresent(renderer);
    _ = c.sleep(c.RENDER_GAMEOVER_DURATION);
    render.clearRenderer();
}

fn initPlayer(playerType: c_int) void {
    //c.initPlayer(playerType);
    spritesCount += 1;
    const p: *c.Snake = c.createSnake(MOVE_STEP, playersCount, @as(c_uint, @intCast(playerType)));
    spriteSnake[@intCast(playersCount)] = p;
    c.appendSpriteToSnake(p, c.SPRITE_KNIGHT, c.SCREEN_WIDTH / 2, c.SCREEN_HEIGHT / 2 + playersCount * 2 * c.UNIT, c.RIGHT);
    playersCount += 1;
}

fn initGame(localPlayers: c_int, remotePlayers: c_int, localFirst: bool) void {
    audio.randomBgm();

    status = 0;
    termCount = 0;
    willTerm = false;
    spritesCount = 0;
    playersCount = 0;
    flasksCount = 0;
    herosCount = 0;

    render.initRenderer();
    render.initCountDownBar();

    // create default hero at (w/2, h/2) (as well push ani)
    var i: usize = 0;
    while (i < localPlayers + remotePlayers) : (i += 1) {
        var playerType: c_int = c.LOCAL;
        if (localFirst) {
            playerType = if (i < localPlayers) c.LOCAL else c.REMOTE;
        } else {
            playerType = if (i < remotePlayers) c.REMOTE else c.LOCAL;
        }
        initPlayer(playerType);
        c.shieldSnake(spriteSnake[i], 300);
    }
    c.initInfo();
    // create map
    c.initRandomMap(0.7, 7, GAME_TRAP_RATE);

    c.clearItemMap();
    // create enemies
    c.initEnemies(spritesSetting);
    map.pushMapToRender();
    bullets = c.createLinkList();
}

pub fn destroySnake(snake: *c.Snake) void {
    if (bullets) |someBullets| {
        var p: ?*c.LinkNode = someBullets.*.head;
        while (p) |someP| {
            const bullet: *c.Bullet = @ptrCast(@alignCast(someP.*.element));
            if (bullet.*.owner == snake) {
                bullet.*.owner = null;
            }
            p = someP.*.nxt;
        }
    }

    var p: ?*c.LinkNode = snake.*.sprites.*.head;
    while (p) |someP| {
        const sprite: *c.Sprite = @ptrCast(@alignCast(someP.*.element));
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
