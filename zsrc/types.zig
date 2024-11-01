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

const c = @import("cdefs.zig").c;

const std = @import("std");
const res = @import("res.zig");
const rnd = @import("render.zig");
const ll = @import("linkedlist.zig");
const spr = @import("sprite.zig");
const gm = @import("game.zig");
const hlp = @import("helper.zig");
const gAllocator = @import("alloc.zig").gAllocator;

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
pub const TEXT_LEN = 1024;

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
    crops: []c.SDL_Rect,
};

pub const Text = struct {
    // Changed text to be an array, it needs to own some dynamic strings.
    // But I don't know if I've introduced a bug in other places.
    //text: [*:0]const u8,

    // The original game has this as an array btw.
    text: [TEXT_LEN]u8 = undefined,
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

    const Self = @This();

    pub fn as(ptr: *anyopaque) *Animation {
        return @ptrCast(@alignCast(ptr));
    }

    pub fn deinit(self: *Self) void {
        if (self.effect) |ef| ef.deinit();
        gAllocator.destroy(self);
    }
};

pub const Effect = struct {
    duration: c_int,
    currentFrame: c_int,
    length: usize,
    keys: []c.SDL_Color,
    mode: c.SDL_BlendMode,

    pub fn init(self: *Effect, duration: c_int, length: usize, mode: c.SDL_BlendMode) void {
        self.keys = gAllocator.alloc(c.SDL_Color, length) catch unreachable;
        self.duration = duration;
        self.length = length;
        self.currentFrame = 0;
        self.mode = mode;
    }

    pub fn deinit(self: ?*Effect) void {
        if (self) |ef| {
            gAllocator.free(ef.keys);
            gAllocator.destroy(ef);
        }
    }

    /// Ensures an exact memberwise replica copy is made of the *Effect
    /// while ensuring the effect.keys are deep copied. This function
    /// allows the caller to choose how the dest *Effect is allocated (stack or heap).
    pub fn copyInto(self: *const Effect, dest: *Effect) void {
        // rc: changed from @memcpy to a memberwise copy.
        dest.* = self.*;

        // With a deep alloc-copy on the keys.
        const len: usize = @intCast(self.length);
        dest.*.keys = gAllocator.alloc(c.SDL_Color, len) catch unreachable;
        for (0..len) |idx| {
            dest.keys[idx] = self.keys[idx];
        }
    }
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
    got: c_int, // Bumped, when a snake has a hero added to the chain.
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
    ITEM_HP_EXTRA_MEDICINE,
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
    self.crops = gAllocator.alloc(c.SDL_Rect, @as(usize, @intCast(frames))) catch unreachable;
}

// NOTE: currently not used because we don't alloc any Textures apparently.
pub fn destroyTexture(self: *Texture) void {
    gAllocator.free(self.crops);
    gAllocator.destroy(self);
}

pub fn initAnimation(
    self: *Animation,
    origin: *Texture,
    effect: ?*const Effect,
    lp: LoopType,
    duration: c_int,
    x: c_int,
    y: c_int,
    flip: c.SDL_RendererFlip,
    angle: f64,
    at: At,
) void {
    self.origin = origin;

    // will deep copy effect
    if (effect) |ef| {
        self.effect = gAllocator.create(Effect) catch unreachable;
        //copyEffect(ef, self.effect.?);
        ef.copyInto(self.effect.?);
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
    const self = gAllocator.create(Animation) catch unreachable;
    initAnimation(
        self,
        origin,
        effect,
        lp,
        duration,
        x,
        y,
        flip,
        angle,
        at,
    );
    return self;
}

pub fn copyAnimation(src: *const Animation, dest: *Animation) void {
    dest.* = src.*;
    if (src.effect) |eff| {
        dest.effect = gAllocator.create(Effect) catch unreachable;
        eff.copyInto(dest.effect.?);
    }
}

pub fn initText(self: *Text, str: [*:0]const u8, color: c.SDL_Color) bool {
    self.color = color;

    _ = c.strcpy(&self.text, str);

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
    const self = gAllocator.create(Text) catch unreachable;
    _ = initText(self, str, color);
    return self;
}

pub fn setText(self: *Text, str: [*:0]const u8) void {
    if (c.strcmp(str, &self.text) == 0) {
        return;
    }

    c.SDL_DestroyTexture(self.origin);
    _ = initText(self, str, self.color);
}

pub fn destroyText(self: *Text) void {
    c.SDL_DestroyTexture(self.origin);
    gAllocator.destroy(self);
}

pub fn initLinkNode(self: *ll.GenericNode) void {
    self.next = null;
    self.prev = null;
    self.data = null;
}

pub fn createLinkNode(element: *anyopaque) *ll.GenericNode {
    // TODO: this needs a try
    const node = gAllocator.create(ll.GenericNode) catch unreachable;
    initLinkNode(node);
    node.data = element;
    return node;
}

pub fn initLinkList(self: *ll.GenericLL) void {
    self.first = null;
    self.last = null;
    self.len = 0;
}

pub fn createLinkList() *ll.GenericLL {
    // TODO: this needs a try
    const list = gAllocator.create(ll.GenericLL) catch unreachable;
    initLinkList(list);
    return list;
}

pub fn pushLinkNodeAtHead(list: *ll.GenericLL, node: *ll.GenericNode) void {
    list.prepend(node);
}

pub fn pushLinkNode(list: *ll.GenericLL, node: *ll.GenericNode) void {
    list.append(node);
}

pub fn removeLinkNode(list: *ll.GenericLL, node: *ll.GenericNode) void {
    list.remove(node);
    gAllocator.destroy(node);
}

pub fn destroyLinkList(self: *ll.GenericLL) void {
    var p = self.first;
    var nxt: ?*ll.GenericNode = undefined;

    while (p) |node| : (p = nxt) {
        nxt = node.next;
        gAllocator.destroy(node);
    }

    gAllocator.destroy(self);
}

pub fn destroyAnimationsByLinkList(list: *ll.GenericLL) void {
    var it = list.first;
    var nxt: ?*ll.GenericNode = undefined;

    while (it) |node| : (it = nxt) {
        nxt = node.next;

        const ani = Animation.as(node.data.?);
        ani.deinit();
        list.remove(node);

        gAllocator.destroy(node);
    }
}

pub fn removeAnimationFromLinkList(self: *ll.GenericLL, ani: *Animation) void {
    var p = self.first;

    while (p) |node| : (p = node.next) {
        if (node.data == @as(?*anyopaque, ani)) {
            removeLinkNode(self, node);
            ani.deinit();
            break;
        }
    }
}

pub fn changeSpriteDirection(self: *ll.GenericNode, newDirection: Direction) void {
    const sprite: *spr.Sprite = @alignCast(@ptrCast(self.data.?));
    if (sprite.direction == newDirection) {
        return;
    }

    sprite.direction = newDirection;
    if (newDirection == .LEFT or newDirection == .RIGHT) {
        sprite.face = newDirection;
    }

    if (self.next) |n| {
        const nextSprite: *spr.Sprite = @alignCast(@ptrCast(n.data));
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
    const score = gAllocator.create(Score) catch unreachable;
    initScore(score);
    return score;
}

pub fn destroyScore(self: *Score) void {
    gAllocator.destroy(self);
}

pub fn calcScore(self: *Score) void {
    if (self.got == 0) {
        self.rank = 0;
        return;
    }

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

pub fn addScore(a: *Score, b: *const Score) void {
    a.got += b.got;
    a.damage += b.damage;
    a.killed += b.killed;
    a.stand += b.stand;
    calcScore(a);
}
