const std = @import("std");

// For now, using a global allocator for everything!
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const gAllocator = gpa.allocator();
