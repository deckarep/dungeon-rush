const c = @import("cdefs.zig").c;

const std = @import("std");
const res = @import("res.zig");
const rnd = @import("render.zig");
const adt = @import("adt.zig");
const spr = @import("sprite.zig");
const gm = @import("game.zig");

pub const BLACK: c.SDL_Color = .{
    .r = 0,
    .g = 0,
    .b = 0,
    .a = 255,
};

pub const WHITE: c.SDL_Color = .{
    .r = 255,
    .g = 255,
    .b = 255,
    .a = 255,
};

pub const BUFF_BEGIN = 0;
pub const BUFF_FROZEN = 0;
pub const BUFF_SLOWDOWN = 1;
pub const BUFF_DEFENCE = 2;
pub const BUFF_ATTACK = 3;
pub const BUFF_END = 4;

pub const POSITION_BUFFER_SIZE = 256;

// Renderer Types
pub const Direction = enum {
    LEFT,
    RIGHT,
    UP,
    DOWN,
};

pub const At = enum {
    AT_TOP_LEFT,
    AT_BOTTOM_LEFT,
    AT_BOTTOM_CENTER,
    AT_CENTER,
};

pub const LoopType = enum {
    LOOP_ONCE,
    LOOP_INFI,
    LOOP_LIFESPAN,
};

pub const Texture = struct {
    origin: *c.SDL_Texture,
    width: c_int,
    height: c_int,
    frames: c_int,
    crops: [*]c.SDL_Rect,
};

pub const Text = struct {
    text: [*:0]const u8,
    width: c_int,
    height: c_int,
    origin: *c.SDL_Texture,
    color: c.SDL_Color,
};

pub const Animation = struct {
    lp: LoopType,
    origin: *Texture,
    effect: ?*Effect,
    duration: c_int,
    currentFrame: c_int,
    x: c_int,
    y: c_int,
    angle: f64,
    flip: c.SDL_RendererFlip,

    // How this animation should be aligned according to (x, y)
    at: At,

    // Points to a Sprite struct. The animation should use the
    // sprite's position
    bind: ?*anyopaque,

    scaled: bool,
    // Determines if the animation should be destroyed when the
    // sprite dies
    dieWithBind: bool,
    // How many seconds the animation should play
    lifeSpan: c_int,
};

pub const Effect = struct {
    duration: c_int,
    currentFrame: c_int,
    length: c_int,
    keys: [*]c.SDL_Color,
    mode: c.SDL_BlendMode,
};

// Game Logic Types
pub const Point = struct {
    x: c_int,
    y: c_int,
};

pub const Score = struct {
    damage: c_int,
    stand: c_int,
    killed: c_int,
    got: c_int,
    rank: f64,
};

pub const BlockType = enum {
    BLOCK_TRAP,
    BLOCK_WALL,
    BLOCK_FLOOR,
    BLOCK_EXIT,
};

pub const Block = struct {
    bp: BlockType,
    x: c_int,
    y: c_int,
    // Block id
    bid: c_int,
    // Used for trap block
    enable: bool,
    ani: *Animation,
};

pub const ItemType = enum {
    ITEM_NONE,
    // Unpicked hero on the floor
    ITEM_HERO,
    // Red meds
    ITEM_HP_MEDICINE,
    // Yellow meds
    ITEM_EXTRA_MEDICINE,
    ITEM_WEAPON,
};

pub const Item = struct {
    type: ItemType,
    id: c_int,
    belong: c_int,
    ani: *Animation,
};

pub fn initTexture(
    self: *Texture,
    origin: *c.SDL_Texture,
    width: c_int,
    height: c_int,
    frames: c_int,
) void {
    self.origin = origin;
    self.width = width;
    self.height = height;
    self.frames = frames;
    self.crops = @alignCast(@ptrCast(c.malloc(@sizeOf(c.SDL_Rect) * @as(usize, @intCast(frames)))));
}

pub fn destroyTexture(self: *Texture) void {
    //     #ifdef DBG
    //   assert(self);
    //     #endif
    c.free(self.crops);
    c.free(self);
}

pub fn initAnimation(self: *Animation, origin: *Texture, effect: ?*const Effect, lp: LoopType, duration: c_int, x: c_int, y: c_int, flip: c.SDL_RendererFlip, angle: f64, at: At) void {
    self.origin = origin;
    // will deep copy effect
    if (effect) |ef| {
        self.effect = @as(*Effect, @ptrCast(@alignCast(c.malloc(@sizeOf(Effect)))));
        copyEffect(ef, self.effect.?);
    } else {
        self.effect = null;
    }
    self.lp = lp;
    self.duration = duration;
    self.currentFrame = 0;
    self.x = x;
    self.y = y;
    self.flip = flip;
    self.angle = angle;
    self.at = at;
    self.bind = null;
    self.dieWithBind = false;
    self.scaled = true;
    self.lifeSpan = duration;
}

pub fn createAnimation(
    origin: *Texture,
    effect: ?*const Effect,
    lp: LoopType,
    duration: c_int,
    x: c_int,
    y: c_int,
    flip: c.SDL_RendererFlip,
    angle: f64,
    at: At,
) *Animation {
    const self: *Animation = @ptrCast(@alignCast(c.malloc(@sizeOf(Animation))));
    initAnimation(self, origin, effect, lp, duration, x, y, flip, angle, at);
    return self;
}

pub fn destroyAnimation(self: *Animation) void {
    destroyEffect(self.effect);
    c.free(self);
}

pub fn copyAnimation(src: *const Animation, dest: *Animation) void {
    dest.* = src.*;
    if (src.effect) |eff| {
        dest.effect = @alignCast(@ptrCast(c.malloc(@sizeOf(Effect))));
        copyEffect(eff, dest.effect.?);
    }
}

pub fn initText(self: *Text, str: [*:0]const u8, color: c.SDL_Color) bool {
    self.color = color;
    self.text = str; // safe to just reference global static read-only strings.

    // Render text surface
    const textSurface = c.TTF_RenderText_Solid(res.font, str, color);
    if (textSurface == null) {
        _ = c.printf("Unable to render text surface! SDL_ttf Error: %s\n", c.TTF_GetError());
    } else {
        // Create texture from surface pixels
        const texture = c.SDL_CreateTextureFromSurface(
            rnd.renderer,
            textSurface,
        );
        self.width = textSurface.*.w;
        self.height = textSurface.*.h;
        c.SDL_FreeSurface(textSurface);
        if (texture == null) {
            _ = c.printf("Unable to create texture from rendered text! SDL Error: %s\n", c.SDL_GetError());
        } else {
            self.origin = texture.?;
            return true;
        }
    }
    return false;
}

pub fn createText(str: [*:0]const u8, color: c.SDL_Color) *Text {
    const self: *Text = @alignCast(@ptrCast(c.malloc(@sizeOf(Text))));
    _ = initText(self, str, color);
    return self;
}

pub fn setText(self: *Text, str: [*c]const u8) void {
    if (!c.strcmp(str, self.text)) {
        return;
    }
    c.SDL_DestroyTexture(self.origin);
    initText(self, str, self.color);
}

pub fn destroyText(self: *Text) void {
    c.SDL_DestroyTexture(self.origin);
    c.free(self);
}

pub fn initEffect(self: *Effect, duration: c_int, length: c_int, mode: c.SDL_BlendMode) void {
    self.keys = @as(
        [*]c.SDL_Color,
        @ptrCast(@alignCast(c.malloc(@sizeOf(c.SDL_Color) * @as(usize, @intCast(length))))),
    );
    self.duration = duration;
    self.length = length;
    self.currentFrame = 0;
    self.mode = mode;
}

// deep copy
pub fn copyEffect(src: *const Effect, dest: *Effect) void {
    // rc: change from memcopy to just regular ass copy.
    dest.* = src.*;

    dest.*.keys = @ptrCast(@alignCast(c.malloc(@sizeOf(c.SDL_Color) * @as(usize, @intCast(src.length)))));
    const len: usize = @intCast(src.length);
    for (0..len) |idx| {
        dest.keys[idx] = src.keys[idx];
    }
}

pub fn destroyEffect(self: ?*Effect) void {
    if (self) |ef| {
        c.free(ef.keys);
        c.free(ef);
    }
}

// rc: Made decision to port over raw C ADT LinkList logic
// eventually, I will do away with this crap in favor of a more
// Zig-friendly approach and delete all this crap.
// First goal: get the game working as-is.
pub fn initLinkNode(self: *adt.LinkNode) void {
    self.nxt = null;
    self.pre = null;
    self.element = null;
}

pub fn createLinkNode(element: *anyopaque) *adt.LinkNode {
    const self: *adt.LinkNode = @alignCast(@ptrCast(c.malloc(@sizeOf(adt.LinkNode))));
    initLinkNode(self);
    self.element = element;
    return self;
}

pub fn initLinkList(self: *adt.LinkList) void {
    self.head = null;
    self.tail = null;
}

pub fn createLinkList() *adt.LinkList {
    const self: *adt.LinkList = @alignCast(@ptrCast(c.malloc(@sizeOf(adt.LinkList))));
    initLinkList(self);
    return self;
}

pub fn pushLinkNodeAtHead(list: *adt.LinkList, node: *adt.LinkNode) void {
    if (list.head == null) {
        list.head = node;
        list.tail = node;
    } else {
        node.nxt = list.head;
        list.head.?.pre = node;
        list.head = node;
    }
}

pub fn pushLinkNode(list: *adt.LinkList, node: *adt.LinkNode) void {
    if (list.head == null) {
        list.head = node;
        list.tail = node;
    } else {
        list.tail.?.nxt = node;
        node.pre = list.tail;

        list.tail = node;
    }
}

pub fn removeLinkNode(list: *adt.LinkList, node: *adt.LinkNode) void {
    if (node.pre) |pre| {
        pre.nxt = node.nxt;
    } else {
        list.head = node.nxt;
    }
    if (node.nxt) |nxt| {
        nxt.pre = node.pre;
    } else {
        list.tail = node.pre;
    }
    c.free(node);
}

pub fn destroyLinkList(self: *adt.LinkList) void {
    var p: ?*adt.LinkNode = self.head;
    var nxt: ?*adt.LinkNode = undefined;

    while (p != null) : (p = nxt) {
        nxt = p.?.nxt;
        c.free(p);
    }

    c.free(self);
}

pub fn destroyAnimationsByLinkList(list: *adt.LinkList) void {
    var p: ?*adt.LinkNode = list.head;
    var nxt: ?*adt.LinkNode = undefined;
    while (p != null) : (p = nxt) {
        nxt = p.?.nxt;
        destroyAnimation(@alignCast(@ptrCast(p.?.element)));
        removeLinkNode(list, p.?);
    }
}

pub fn removeAnimationFromLinkList(self: *adt.LinkList, ani: *Animation) void {
    var p: *adt.LinkNode = self.head;
    while (p != null) : (p = p.nxt) {
        if (p.element == ani) {
            removeLinkNode(self, p);
            destroyAnimation(ani);
            break;
        }
    }
}

pub fn changeSpriteDirection(self: *adt.LinkNode, newDirection: Direction) void {
    const sprite: *spr.Sprite = @alignCast(@ptrCast(self.element.?));
    if (sprite.direction == newDirection) {
        return;
    }

    sprite.direction = newDirection;
    if (newDirection == .LEFT or newDirection == .RIGHT) {
        sprite.face = newDirection;
    }

    if (self.nxt) |n| {
        const nextSprite: *spr.Sprite = @alignCast(@ptrCast(n.element));
        const slot: spr.PositionBufferSlot = .{
            .x = sprite.x,
            .y = sprite.y,
            .direction = sprite.direction,
        };
        spr.pushToPositionBuffer(&nextSprite.posBuffer, slot);
    }
}

fn initScore(score: *Score) void {
    // original => memset(score, 0, sizeof(Score)
    // r.c.: Not sure if this just maps over equiv to original C code.
    score.* = std.mem.zeroes(Score);
}

pub fn createScore() *Score {
    const score: *Score = @alignCast(@ptrCast(c.malloc(@sizeOf(Score))));
    initScore(score);
    return score;
}

pub fn destroyScore(self: *Score) void {
    c.free(self);
}

fn calcScore(self: *Score) void {
    if (self.got == 0) {
        self.rank = 0;
        return;
    }

    //extern int gameLevel;
    const gl: f64 = @floatFromInt(gm.gameLevel);
    const dmg: f64 = @floatFromInt(self.damage);
    const got: f64 = @floatFromInt(self.got);
    const stand: f64 = @floatFromInt(self.stand);
    const killed: f64 = @floatFromInt(self.killed);

    self.rank = dmg / got +
        stand / got + got * 50 +
        killed * 100;
    self.rank *= gl + 1;
}

pub fn addScore(a: *Score, b: *Score) void {
    a.got += b.got;
    a.damage += b.damage;
    a.killed += b.killed;
    a.stand += b.stand;
    calcScore(a);
}
