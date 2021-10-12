const std = @import("std");
const meta = @import("std").meta;
const stdout = std.io.getStdOut().writer();

const c = @import("c_headers.zig").c;

pub extern var animationsList: [c.ANIMATION_LINK_LIST_NUM]c.LinkList;

pub fn initAnimation(self: *c.Animation, origin: *c.Texture, effect: ?*const c.Effect, lp: c.LoopType, duration: c_int, x: c_int, y: c_int, flip: c.SDL_RendererFlip, angle: f64, at: c.At) void {
    // will deep copy effect
    self.*.origin = origin;
    if (effect != null) {
        self.*.effect = @ptrCast([*c]c.Effect, @alignCast(meta.alignment(c.Effect), c.malloc(@sizeOf(c.Effect))));
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

pub fn destroyAnimationsByLinkList(list: *c.LinkList) void {
    var p: [*c]c.LinkNode = list.*.head;
    var nxt: [*c]c.LinkNode = null;

    while (p != undefined) {
        stdout.print("type of while p: {s}\n", .{@TypeOf(p)}) catch unreachable;
        nxt = p.*.nxt;

        // Note: Zig won't cast implicitly from a ?*c_void' pointer.
        // We pull out the element and cast to an Animation type.
        const ani: *c.Animation = @ptrCast([*c]c.Animation, @alignCast(@import("std").meta.alignment([*c]c.Animation), p.*.element));
        destroyAnimation(ani);
        removeLinkNode(list, p);
    }
}

pub fn createAnimation(origin: *c.Texture, effect: ?*const c.Effect, lp: c.LoopType, duration: c_int, x: c_int, y: c_int, flip: c.SDL_RendererFlip, angle: f64, at: c.At) *c.Animation {
    var self: *c.Animation = @ptrCast([*c]c.Animation, @alignCast(meta.alignment(c.Animation), c.malloc(@sizeOf(c.Animation))));
    initAnimation(self, origin, effect, lp, duration, x, y, flip, angle, at);
    return self;
}

pub fn destroyAnimation(self: *c.Animation) void {
    destroyEffect(self.*.effect);
    c.free(self);
}

pub fn initEffect(self: *c.Effect, duration: c_int, length: c_int, mode: c.SDL_BlendMode) void {
    self.*.keys = @ptrCast([*c]c.SDL_Color, @alignCast(meta.alignment(c.Effect), c.malloc(@sizeOf(c.SDL_Color) * @intCast(c_ulong, length))));
    self.*.duration = duration;
    self.*.length = length;
    self.*.currentFrame = 0;
    self.*.mode = mode;
}

// deep copy
pub fn copyEffect(src: [*c]const c.Effect, dest: *c.Effect) void {
    _ = c.memcpy(dest, src, @sizeOf(c.Effect));
    dest.*.keys = @ptrCast([*c]c.SDL_Color, @alignCast(meta.alignment(c.SDL_Color), c.malloc(@sizeOf(c.SDL_Color) * @intCast(c_ulong, src.*.length))));
    _ = c.memcpy(dest.*.keys, src.*.keys, @sizeOf(c.SDL_Color) * @intCast(c_ulong, src.*.length));
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
