const std = @import("std");
const testing = std.testing;

const root = @import("root.zig");

test "basic add functionality" {
    try testing.expect(root.add(20, 22) == 42);
}
