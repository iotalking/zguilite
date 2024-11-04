const std = @import("std");
const guilite = @import("./guilite.zig");
const _3d = @import("./3d.zig");

pub fn main() !void {
    guilite.init();

    // const color_bytes = 4;
    // const screen_width: int = 240;
    // const screen_height: int = 320;
    var screen_width: int = 0;
    var screen_height: int = 0;
    var color_bytes: int = 0;
    const devfb = try get_dev_fb("/dev/fb0", &screen_width, &screen_height, &color_bytes);
    if (devfb == null) {
        return error.devfb;
    }
    // std.log.debug("screen:({}x{})*{} devfb:{*}", .{ screen_width, screen_height, color_bytes, devfb });
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const mem_fb = try allocator.alloc(u8, @as(usize, @as(u32, @bitCast(screen_width * screen_height * color_bytes))));
    defer {
        allocator.free(mem_fb);
        _ = gpa.deinit();
    }

    const i16_height: i16 = @truncate(screen_height);
    const i16_width: i16 = @truncate(screen_width);
    const fbuf: [*]u8 = @ptrCast(devfb.?);
    // const fbuf: [*]u8 = @ptrCast(mem_fb);
    var desktop = c_desktop{};
    var btn: guilite.c_button = guilite.c_button{};
    var label: guilite.c_label = guilite.c_label{};
    var edit: guilite.c_edit = guilite.c_edit{};
    var list_box: guilite.c_list_box = guilite.c_list_box{};
    var dialog = guilite.c_dialog{};
    const ID_BTN = 1;
    const ID_DESKTOP = 2;
    const ID_LABEL = 3;
    const ID_DIALOG = 4;
    const ID_KEYBOARD = 5;
    const ID_EDIT = 6;
    const ID_LIST_BOX = 7;

    // _ = btn;
    var s_desktop_children = [_]?*const guilite.WND_TREE{
        &guilite.WND_TREE{
            .p_wnd = dialog.asWnd(), //
            .resource_id = ID_DIALOG,
            .str = "千里辞",
            .x = 10,
            .y = 10,
            .width = 500,
            .height = 80,
            .p_child_tree = null,
        },
        &guilite.WND_TREE{
            .p_wnd = btn.asWnd(), //
            .resource_id = ID_BTN,
            .str = "吴朝辞",
            .x = 10,
            .y = 10,
            .width = 500,
            .height = 80,
            .p_child_tree = null,
        },
        &guilite.WND_TREE{
            .p_wnd = label.asWnd(), //
            .resource_id = ID_LABEL,
            .str = "朝辞白帝彩云间千里江陵一日还两岸猿声啼不住轻舟已过万重山",
            .x = 10,
            .y = 100,
            .width = 500,
            .height = 80,
            .p_child_tree = null,
        },
        &guilite.WND_TREE{
            .p_wnd = edit.asWnd(), //
            .resource_id = ID_EDIT,
            .str = "edit",
            .x = 10,
            .y = 200,
            .width = 500,
            .height = 80,
            .p_child_tree = null,
        },
        &guilite.WND_TREE{
            .p_wnd = list_box.asWnd(), //
            .resource_id = ID_LIST_BOX,
            .str = "listbox",
            .x = 10,
            .y = 300,
            .width = 200,
            .height = 30,
            .p_child_tree = null,
        },
        null,
    };
    list_box.clear_item();
    try list_box.add_item("里江");
    try list_box.add_item("猿声啼不住");
    std.log.debug("main list_box:{*} item0:{s}", .{ &list_box, list_box.m_item_array[0] });

    const usize_width = @as(usize, @as(u32, @bitCast(screen_width)));
    const usize_height = @as(usize, @as(u32, @bitCast(screen_height)));
    const fb32: [*]u32 = @ptrCast(@alignCast(mem_fb));
    std.log.debug("fb32:{*}", .{fb32});
    for (10..usize_height - 10) |y| {
        for (10..usize_width - 10) |x| {
            fb32[y * usize_width + x] = 0xff_ff_ff_ff;
        }
    }

    std.log.debug("s_desktop_children[0]:{*},s_desktop_children[0].resource_id:{d}", .{ s_desktop_children[0], s_desktop_children[0].?.resource_id });
    var _display: guilite.c_display = .{};
    try _display.init2(fbuf, screen_width, screen_height, screen_width, screen_height, color_bytes, 3, null);
    const surface = try _display.alloc_surface(.Z_ORDER_LEVEL_1, guilite.c_rect.init2(0, 0, screen_width, screen_height));
    surface.set_active(true);
    surface.draw_line(0, 0, screen_width - 1, 500, guilite.GL_RGB(255, 200, 100), guilite.Z_ORDER_LEVEL_1);
    desktop.asWnd().set_surface(surface);
    _ = desktop.wnd.connect(null, ID_DESKTOP, null, 0, 0, i16_width, i16_height, &s_desktop_children);

    desktop.asWnd().show_window();

    // try dialog.open_dialog(true);

    var keyboard = guilite.c_keyboard{};

    _ = keyboard.open_keyboard(edit.asWnd(), ID_KEYBOARD, .STYLE_ALL_BOARD, guilite.WND_CALLBACK.init(&keyboard, &struct {
        fn onclick(kb: *guilite.c_keyboard, id: int, param: int) void {
            std.log.debug("onkbclick.onclick keyboard:{*}", .{kb});
            // _ = this;
            _ = id;
            _ = param;
        }
    }.onclick));
    keyboard.asWnd().show_window();

    // _ = _display.flush_screen(&_display, 0, 0, screen_width, screen_height, @ptrCast(mem_fb), screen_width);
    // _display.fill_rect(&_display, 0, 0, 100, 100, @as(u32, 0xff_00));
    // surface.draw_rect_pos(0, 0, 100, 100, guilite.GL_RGB(200, 0, 0), @intFromEnum(guilite.Z_ORDER_LEVEL.Z_ORDER_LEVEL_1), 10);
    // surface.fill_rect(guilite.c_rect{ .m_left = 30, .m_top = 200, .m_right = 400, .m_bottom = 600 }, guilite.GL_RGB(0, 100, 0), 1);
    // try _3d.create_ui(&_display);
    std.log.debug("main end", .{});
    while (true) {}
}

const A = struct {
    fn Hello(a: *A, b: u32, c: u32) void {
        std.log.err("AAAA:{*} b:{d} c:{d}", .{ a, b, c });
    }
};
test "test [*]65" {
    var aa = A{};

    const f: *const fn (*anyopaque, u32) void = @ptrCast(&A.Hello);
    @call(.auto, f, .{ &aa, 2 });
    var a: [3][1]f64 = .{ .{0.1}, .{0.2}, .{0.3} };
    std.log.err("a:{any}", .{a});
    const b: [*]f64 = @ptrCast(&a[0][0]);
    for (0..3) |i| {
        std.log.err("b:{any}", .{b[i]});
    }
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

const linux = @cImport({
    @cInclude("stdlib.h");
    @cInclude("string.h");
    @cInclude("stdio.h");
    @cInclude("fcntl.h");
    @cInclude("sys/ioctl.h");
    @cInclude("sys/shm.h");
    @cInclude("unistd.h");
    @cInclude("sys/mman.h");
    @cInclude("linux/fb.h");
    @cInclude("errno.h");
    @cInclude("sys/stat.h");
});

const printf = linux.printf;
const int = c_int;
fn get_dev_fb(path: []const u8, width: *int, height: *int, color_bytes: *int) !?*anyopaque {
    const fd = linux.open(@ptrCast(path), linux.O_RDWR);
    if (0 > fd) {
        return error.open_fb;
    }

    var vinfo: linux.fb_var_screeninfo = undefined;
    if (0 > linux.ioctl(fd, linux.FBIOGET_VSCREENINFO, &vinfo)) {
        // printf("get fb info failed!\n");
        // _exit(-1);
        return error.ioctl_screen_info;
    }

    width.* = @bitCast(vinfo.xres);
    height.* = @bitCast(vinfo.yres);
    const bits_per_pixel: int = @bitCast(vinfo.bits_per_pixel);
    color_bytes.* = @divExact(bits_per_pixel, 8);
    const ucolor_bytes: c_uint = @bitCast(color_bytes.*);
    if (width.* & 0x3 != 0) {
        _ = printf("Warning: vinfo.xres should be divided by 4!\nChange your display resolution to meet the rule.\n");
    }
    _ = printf("vinfo.xres=%d\n", vinfo.xres);
    _ = printf("vinfo.yres=%d\n", vinfo.yres);
    _ = printf("vinfo.bits_per_pixel=%d\n", vinfo.bits_per_pixel);

    const fbp = linux.mmap(@ptrFromInt(0), (vinfo.xres * vinfo.yres * ucolor_bytes), linux.PROT_READ | linux.PROT_WRITE, linux.MAP_SHARED, fd, 0);
    if (fbp == null) {
        _ = printf("mmap fb failed!\n");
        // linux._exit(-1);
        return error.mmap_fb;
    }
    _ = linux.memset(fbp, 0, (vinfo.xres * vinfo.yres * ucolor_bytes));
    return fbp;
}
