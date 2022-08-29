const std = @import("std");
const stdout = std.io.getStdOut().writer();

const c = @import("c_headers.zig").c;

const zTypes = @import("types.zig");

extern var renderer: *c.SDL_Renderer;
pub extern var animationsList: [c.ANIMATION_LINK_LIST_NUM]c.LinkList;

// Extern for now.
pub extern var textures: [c.TEXTURES_SIZE]c.Texture;
pub extern var countDownBar: *c.Animation;

var renderFrames: c_ulonglong = undefined;

pub fn initRenderer() void {
    renderFrames = 0;
    var i: usize = 0;
    while (i < c.ANIMATION_LINK_LIST_NUM) : (i += 1) {
        c.initLinkList(&animationsList[i]);
    }
}

pub fn initCountDownBar() void {
    _ = createAndPushAnimation(&animationsList[c.RENDER_LIST_UI_ID], &textures[c.RES_SLIDER], null, c.LOOP_INFI, 1, c.SCREEN_WIDTH / 2 - 128, 10, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
    countDownBar = createAndPushAnimation(&animationsList[c.RENDER_LIST_UI_ID], &textures[c.RES_BAR_BLUE], null, c.LOOP_INFI, 1, c.SCREEN_WIDTH / 2 - 128, 10, c.SDL_FLIP_NONE, 0, c.AT_TOP_LEFT);
}

pub fn renderUi() void {
    // c.RENDER_BG_COLOR => 25,17,23
    _ = c.SDL_SetRenderDrawColor(renderer, 25, 17, 23, 255);
    _ = c.SDL_RenderClear(renderer);

    var i: usize = 0;
    while (i < c.ANIMATION_LINK_LIST_NUM) : (i += 1) {
        c.updateAnimationLinkList(&animationsList[i]);
        if (i == c.RENDER_LIST_SPRITE_ID) {
            c.renderAnimationLinkListWithSort(&animationsList[i]);
        } else {
            c.renderAnimationLinkList(&animationsList[i]);
        }
    }
}

pub fn renderCenteredText(text: *const c.Text, x: c_int, y: c_int, scale: f64) c.SDL_Point {
    const width: c_int = @floatToInt(c_int, @intToFloat(f64, text.*.width) * scale + 0.5);
    const height: c_int = @floatToInt(c_int, @intToFloat(f64, text.*.height) * scale + 0.5);

    const dst: c.SDL_Rect = c.SDL_Rect{
        .x = x - @divTrunc(width, 2),
        .y = y - @divTrunc(height, 2),
        .w = width,
        .h = height,
    };
    _ = c.SDL_RenderCopy(renderer, text.*.origin, null, &dst);
    return c.SDL_Point{
        .x = x - @divTrunc(width, 2),
        .y = y - @divTrunc(height, 2),
    };
}

fn blacken(duration: i32) void {
    // TODO: handle sdl return errors properly in zig.
    _ = c.SDL_SetRenderDrawBlendMode(renderer, c.SDL_BLENDMODE_BLEND);
    const rect = c.SDL_Rect{
        .x = 0,
        .y = 0,
        .w = c.SCREEN_WIDTH,
        .h = c.SCREEN_HEIGHT,
    };
    // TODO: the args were formally this define: RENDER_BG_COLOR
    _ = c.SDL_SetRenderDrawColor(renderer, 25, 17, 23, 85);
    var i: usize = 0;
    while (i < duration) : (i += 1) {
        _ = c.SDL_RenderFillRect(renderer, &rect);
        _ = c.SDL_RenderPresent(renderer);
    }
}

pub fn blackout() void {
    blacken(c.RENDER_BLACKOUT_DURATION);
}

pub fn clearRenderer() void {
    var i: usize = 0;

    //stdout.print("type of LinkList: {s}\n", .{@TypeOf(&animationsList[i])}) catch unreachable;

    while (i < c.ANIMATION_LINK_LIST_NUM) : (i += 1) {
        //c.destroyAnimationsByLinkList(&animationsList[i]);
        // NOTE: won't compile because header types are confused somehow for the arg into the zig world.
        zTypes.destroyAnimationsByLinkList(&animationsList[i]);
    }
    _ = c.SDL_RenderClear(renderer);
}

pub fn createAndPushAnimation(list: *c.LinkList, texture: *c.Texture, effect: ?*const c.Effect, lp: c.LoopType, duration: c_int, x: c_int, y: c_int, flip: c.SDL_RendererFlip, angle: f64, at: c.At) *c.Animation {
    var ani: *c.Animation = c.createAnimation(texture, effect, lp, duration, x, y, flip, angle, at);
    var node: *c.LinkNode = c.createLinkNode(ani);
    c.pushLinkNode(list, node);
    return ani;
}

pub fn updateAnimationOfSprite(self: *c.Sprite) void {
    var ani: *c.Animation = self.*.ani;
    ani.*.x = self.*.x;
    ani.*.y = self.*.y;
    ani.*.flip = if (self.*.face == c.RIGHT) c.SDL_FLIP_NONE else c.SDL_FLIP_HORIZONTAL;
}
