const std = @import("std");
const stdout = std.io.getStdOut().writer();

const c = @import("c_headers.zig").c;

// NOTE: i'm simply going to forward to C calls in this file. Not sure I care about storing scores in a format this way (or at all).

pub fn updateLocalRanklist(score: *c.Score) void {
    c.updateLocalRanklist(score);
}

pub fn destroyRanklist(n: c_int, scores: [*c][*c]c.Score) void {
    c.destroyRanklist(n, scores);
}

//Score** insertScoreToRanklist(Score*, int*, Score**);
//void writeRanklist(const char*, int, Score**);
//Score** readRanklist(const char* path, int* n);
