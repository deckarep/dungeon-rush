const std = @import("std");

// For now, using a global allocator for everything!
pub var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const gAllocator = gpa.allocator();
