const std = @import("std");

/// This is a generic queue built on top of a fixed size array.
pub fn BoundedArrayQueue(comptime Child: type, comptime bufferSize: usize) type {
    return struct {
        const Self = @This();

        buffer: [bufferSize]Child = undefined,
        count: usize,

        /// Creates and initializes an empty queue structure.
        pub fn init() Self {
            return .{ .count = 0 };
        }

        /// Only peeks at the top of the queue, but this doesn't do any
        /// modification to the queue itself.
        pub fn peek(self: *const Self) ?Child {
            if (self.count > 0) {
                return self.buffer[0];
            }
            return null;
        }

        /// This enqueues the value to be at the head of the queue.
        pub fn enqueue(self: *Self, value: Child) void {
            std.debug.assert(self.count < self.buffer.len);
            self.buffer[self.count] = value;
            self.count += 1;
        }

        /// Does the work of shifting over the elements
        /// in the queue and returns what was at the top.
        pub fn dequeue(self: *Self) ?Child {
            if (self.count > 0) {
                return self.popAndSlideOne();
            }
            return null;
        }

        /// Does the primary work of shifting everything over
        /// and returning whatever was the first out.
        fn popAndSlideOne(self: *Self) Child {
            const item = self.buffer[0];
            self.count -= 1;

            for (0..self.count + 1) |idx| {
                self.buffer[idx] = self.buffer[idx + 1];
            }

            return item;
        }
    };
}

fn testQ() void {
    var q = BoundedArrayQueue(u8, 10).init();
    q.enqueue(8);
    q.enqueue(6);
    q.enqueue(7);
    q.enqueue(5);
    q.enqueue(3);
    q.enqueue(0);
    q.enqueue(9);

    std.debug.assert(q.count == 7);
    std.debug.assert(q.peek() == 8);

    var r = q.dequeue();
    std.debug.assert(r == 8);

    r = q.dequeue();
    std.debug.assert(r == 6);

    r = q.dequeue();
    std.debug.assert(r == 7);

    r = q.dequeue();
    std.debug.assert(r == 5);

    r = q.dequeue();
    std.debug.assert(r == 3);

    r = q.dequeue();
    std.debug.assert(r == 0);

    r = q.dequeue();
    std.debug.assert(r == 9);

    r = q.dequeue();
    std.debug.assert(r == null);
    std.debug.assert(q.count == 0);

    std.process.exit(0);
}
