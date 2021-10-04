const std = @import("std");
const stdout = std.io.getStdOut().writer();

const c = @import("c_headers.zig").c;

pub extern var animationsList: [c.ANIMATION_LINK_LIST_NUM]c.LinkList;

pub fn destroyAnimationsByLinkList(list: *c.LinkList) void {
    var p:[*c]c.LinkNode = list.*.head;
    var nxt:[*c]c.LinkNode = null;

    while( p != undefined){
        stdout.print("type of while p: {s}\n", .{@TypeOf(p)}) catch unreachable;
        nxt = p.*.nxt;

        // Note: Zig won't cast implicitly from a ?*c_void' pointer.
        // We pull out the element and cast to an Animation type.
        const ani:*c.Animation = @ptrCast([*c]c.Animation, @alignCast(@import("std").meta.alignment([*c]c.Animation), p.*.element));
        c.destroyAnimation(ani);
        c.removeLinkNode(list, p);
    }
}