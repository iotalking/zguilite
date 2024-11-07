const std = @import("std");
const x11 = @import("./x11.zig");
const int = c_int;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const screenWidth = 800;
    const screenHeight = 600;
    var colorBytes: int = 4;
    const frameBuffer = try x11.createFrameBuffer(allocator, screenWidth, screenHeight, &colorBytes);
    _ = frameBuffer;
    try x11.appLoop();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
