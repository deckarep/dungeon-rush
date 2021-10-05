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
        destroyAnimation(ani);
        removeLinkNode(list, p);
    }
}

pub fn destroyAnimation(self: *c.Animation) void{
  c.destroyEffect(self.*.effect);
  c.free(self);
}

pub fn removeLinkNode(list:*c.LinkList, node:*c.LinkNode) void{
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