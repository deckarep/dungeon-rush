pub const LinkNode = struct {
    const Self = @This();

    element: ?*anyopaque,
    pre: ?*Self,
    nxt: ?*Self,
};

pub const LinkList = struct {
    head: ?*LinkNode,
    tail: ?*LinkNode,
};
