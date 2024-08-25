const std = @import("std");
const guilite = @import("./guilite.zig");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!

    _ = guilite.GL_RGB_32_to_16(0xff);
    _ = guilite.c_wnd.init();

    var w: my_wnd = .{};
    var pWnd = w.asWnd();
    pWnd.on_paint();
}

const my_wnd = struct {
    wnd: guilite.c_wnd = guilite.c_wnd.init(),
    pub fn asWnd(this: *my_wnd) *guilite.c_wnd {
        this.wnd.m_vtable.on_paint = my_wnd.on_paint;
        return @ptrCast(this);
    }
    fn on_paint(this: *guilite.c_wnd) void {
        _ = this;
        std.log.debug("my_wnd on paint", .{});
    }
};
test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
