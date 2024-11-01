// Open Source Initiative OSI - The MIT License (MIT):Licensing

// The MIT License (MIT)
// Copyright (c) 2024 Ralph Caraveo (deckarep@gmail.com)

// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
const std = @import("std");
const tps = @import("types.zig");

// NOTE: r.c. - I made a decision to replace the original C ADT-style doubly
// linked-list with a single generic doubly linked-list using the Zig
// standard library where the data is just an opaque pointer type.
// This means, I still need to type cast everywhere unfortunately.

// I may or may not follow-up by breaking them out against each type
// specified below in Phase 2.

// Phase 1: Just start off by storing a pointer to a nullable opaque type.
// Original C-style ADT linked list has been deprecated in favor of this!
// This is complete!
pub const GenericLL = std.DoublyLinkedList(?*anyopaque);
pub const GenericNode = GenericLL.Node;

// Phase 2: Break these out into type-safe individual linked lists. (maybe)
// Not started.
//      Need one for: *Animation
//      Need one for: *Bullet
//      Need one for: *Sprite
