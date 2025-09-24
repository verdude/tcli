const std = @import("std");

// Public library API
pub fn init() void {}

pub fn add(a: anytype, b: anytype) @TypeOf(a + b) {
    return a + b;
}
