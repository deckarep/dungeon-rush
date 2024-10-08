const std = @import("std");
const meta = @import("std").meta;
const stdout = std.io.getStdOut().writer();

const c = @import("c_headers.zig").c;

pub extern var animationsList: [c.ANIMATION_LINK_LIST_NUM]c.LinkList;
extern var font: ?*c.TTF_Font;
extern var renderer: *c.SDL_Renderer;

pub fn initAnimation(self: *c.Animation, origin: *c.Texture, effect: ?*const c.Effect, lp: c.LoopType, duration: c_int, x: c_int, y: c_int, flip: c.SDL_RendererFlip, angle: f64, at: c.At) void {
    // will deep copy effect
    self.*.origin = origin;
    if (effect != null) {
        self.*.effect = @ptrCast(@alignCast(c.malloc(@sizeOf(c.Effect))));
        copyEffect(effect, self.*.effect);
    } else {
        self.*.effect = null;
    }
    self.*.lp = lp;
    self.*.duration = duration;
    self.*.currentFrame = 0;
    self.*.x = x;
    self.*.y = y;
    self.*.flip = flip;
    self.*.angle = angle;
    self.*.at = at;
    self.*.bind = null;
    self.*.dieWithBind = false;
    self.*.scaled = true;
    self.*.lifeSpan = duration;
}

pub fn initText(txt: *c.Text, str: [*c]const u8, color: c.SDL_Color) bool {
    txt.*.color = color;
    _ = c.strcpy(&txt.*.text[0], str);
    // Render text surface
    const textSurface = c.TTF_RenderText_Solid(font, str, color);
    if (textSurface == null) {
        stdout.print("Unable to render text surface! SDL_ttf Error: {s}\n", .{c.TTF_GetError()}) catch unreachable;
    } else {
        // Create texture from surface pixels
        const texture = c.SDL_CreateTextureFromSurface(renderer, textSurface);
        txt.*.width = textSurface.*.w;
        txt.*.height = textSurface.*.h;
        c.SDL_FreeSurface(textSurface);
        if (texture == null) {
            stdout.print("Unable to create texture from rendered text! SDL Error: {s}\n", .{c.SDL_GetError()}) catch unreachable;
        } else {
            txt.*.origin = texture;
            return true;
        }
    }
    return false;
}

// Crash here in this routine.
pub fn destroyAnimationsByLinkList(list: *c.LinkList) void {
    var p: ?*c.LinkNode = list.head;

    while (p) |node| {
        const nxt = node.nxt;
        const ani: *c.Animation = @ptrCast(@alignCast(node.element));
        destroyAnimation(ani);
        removeLinkNode(list, node);
        p = nxt;
    }
}

pub fn createAnimation(origin: *c.Texture, effect: ?*const c.Effect, lp: c.LoopType, duration: c_int, x: c_int, y: c_int, flip: c.SDL_RendererFlip, angle: f64, at: c.At) *c.Animation {
    const self: *c.Animation = @ptrCast(@alignCast(c.malloc(@sizeOf(c.Animation))));
    initAnimation(self, origin, effect, lp, duration, x, y, flip, angle, at);
    return self;
}

pub fn destroyAnimation(self: *c.Animation) void {
    destroyEffect(self.*.effect);
    c.free(self);
}

pub fn initEffect(self: *c.Effect, duration: c_int, length: c_int, mode: c.SDL_BlendMode) void {
    self.*.keys = @ptrCast(@alignCast(c.malloc(@sizeOf(c.SDL_Color) * @as(usize, @intCast(length)))));
    self.*.duration = duration;
    self.*.length = length;
    self.*.currentFrame = 0;
    self.*.mode = mode;
}

// deep copy
pub fn copyEffect(src: [*c]const c.Effect, dest: *c.Effect) void {
    _ = c.memcpy(dest, src, @sizeOf(c.Effect));
    dest.*.keys = @ptrCast(@alignCast(c.malloc(@sizeOf(c.SDL_Color) * @as(usize, @intCast(src.*.length)))));
    _ = c.memcpy(dest.*.keys, src.*.keys, @sizeOf(c.SDL_Color) * @as(usize, @intCast(src.*.length)));
}

pub fn destroyEffect(self: [*c]c.Effect) void {
    if (self != null) {
        c.free(self.*.keys);
        c.free(self);
    }
}

pub fn pushLinkNode(list: *c.LinkList, node: *c.LinkNode) void {
    if (list.*.head == null) {
        list.*.head = node;
        list.*.tail = node;
    } else {
        list.*.tail.*.nxt = node;
        node.*.pre = list.*.tail;

        list.*.tail = node;
    }
}

pub fn removeLinkNode(list: *c.LinkList, node: *c.LinkNode) void {
    if (node.*.pre != null) {
        node.*.pre.*.nxt = node.*.nxt;
    } else {
        list.*.head = node.*.nxt;
    }

    if (node.*.nxt != null) {
        node.*.nxt.*.pre = node.*.pre;
    } else {
        list.*.tail = node.*.pre;
    }

    c.free(node);
}

pub fn destroyLinkList(self: *c.LinkList) void {
    // TODO: port this over.
    c.destroyLinkList(self);
}

pub fn destroyScore(self: *c.Score) void {
    c.free(self);
}

pub fn destroyText(self: *c.Text) void {
    _ = c.SDL_DestroyTexture(self.*.origin);
    c.free(self);
}

pub fn createScore() *c.Score {
    const score: *c.Score = @ptrCast(@alignCast(c.malloc(@sizeOf(c.Score))));
    c.initScore(score);
    return score;
}

pub fn addScore(a: *c.Score, b: *c.Score) void {
    a.*.got += b.*.got;
    a.*.damage += b.*.damage;
    a.*.killed += b.*.killed;
    a.*.stand += b.*.stand;
    c.calcScore(a);
}
