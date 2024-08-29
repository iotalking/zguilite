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

    const color_bytes = 2;
    const screen_width = 240;
    const screen_height = 320;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const fbuf = try allocator.alloc(u8, screen_width * screen_height * color_bytes);
    defer {
        allocator.free(fbuf);
        _ = gpa.deinit();
    }
    var desktop = c_desktop{};
    var btn: guilite.c_button = guilite.c_button{};
    const ID_BTN = 1;
    const ID_DESKTOP = 2;
    var s_desktop_children = [_]?*const guilite.WND_TREE{
        &guilite.WND_TREE{
            .p_wnd = btn.asWnd(), //
            .resource_id = ID_BTN,
            .str = null,
            .x = 10,
            .y = 10,
            .width = 50,
            .height = 50,
            .p_child_tree = null,
        },
        null,
    };

    std.log.debug("s_desktop_children[0]:{*},s_desktop_children[0].resource_id:{d}", .{ s_desktop_children[0], s_desktop_children[0].?.resource_id });
    var _display: guilite.c_display = .{};
    try _display.init2(@ptrCast(@constCast(&fbuf[0])), screen_width, screen_height, screen_width, screen_height, color_bytes, 1, null);
    const surface = try _display.alloc_surface(.Z_ORDER_LEVEL_1, guilite.c_rect.init2(0, 0, screen_width, screen_height));
    surface.set_active(true);
    desktop.asWnd().set_surface(surface);
    _ = desktop.wnd.connect(null, ID_DESKTOP, null, 0, 0, screen_width, screen_height, &s_desktop_children);
    desktop.asWnd().show_window();
    std.log.debug("main end", .{});
}

const c_desktop = struct {
    wnd: guilite.c_wnd = .{
        .m_class = "c_desktop",
    },
    pub fn asWnd(this: *c_desktop) *guilite.c_wnd {
        this.wnd.m_vtable.on_paint = c_desktop.on_paint;
        return &this.wnd;
    }
    fn on_paint(this: *guilite.c_wnd) void {
        _ = this;
        std.log.debug("c_desktop on paint", .{});
    }
};
test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
