const std = @import("std");
const guilite = @import("./guilite.zig");
const _3d = @import("./3d.zig");
const x11 = @import("./x11.zig");
const int = c_int;
const uint = c_uint;

pub fn main() !void {
    guilite.init();

    const screen_width: int = 1024;
    const screen_height: int = 800;
    var color_bytes: uint = 0;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const i16_height: i16 = @truncate(screen_height);
    const i16_width: i16 = @truncate(screen_width);
    const frameBuffer = try x11.createFrameBuffer(allocator, screen_width, screen_height, &color_bytes);
    defer allocator.free(frameBuffer);

    const fbuf: [*]u8 = frameBuffer.ptr;

    var desktop = Desktop{};
    var btn: guilite.Button = guilite.Button{};
    var label: guilite.Label = guilite.Label{};
    var edit: guilite.Edit = guilite.Edit{};
    var list_box: guilite.ListBox = guilite.ListBox{};
    var dialog = guilite.Dialog{};
    var spin_box: guilite.SpinBox = guilite.SpinBox{};
    var table: guilite.Table = guilite.Table{};
    const ID_BTN = 1;
    const ID_DESKTOP = 2;
    const ID_LABEL = 3;
    const ID_DIALOG = 4;
    const ID_KEYBOARD = 5;
    const ID_EDIT = 6;
    const ID_LIST_BOX = 7;
    const ID_SPIN_BOX = 8;
    // _ = btn;
    var s_desktop_children = [_]?*const guilite.WND_TREE{
        &.{
            .p_wnd = dialog.asWnd(), //
            .resource_id = ID_DIALOG,
            .str = "千里辞",
            .x = 10,
            .y = 10,
            .width = 500,
            .height = 80,
            .p_child_tree = null,
        },
        &.{
            .p_wnd = btn.asWnd(), //
            .resource_id = ID_BTN,
            .str = "吴朝辞",
            .x = 10,
            .y = 10,
            .width = 500,
            .height = 80,
            .p_child_tree = null,
        },
        &.{
            .p_wnd = label.asWnd(), //
            .resource_id = ID_LABEL,
            .str = "123朝辞白帝彩云间千里江陵一日还两岸猿声啼不住轻舟已过万重山",
            .x = 10,
            .y = 100,
            .width = 500,
            .height = 80,
            .p_child_tree = null,
        },
        &.{
            .p_wnd = edit.asWnd(), //
            .resource_id = ID_EDIT,
            .str = "edit",
            .x = 10,
            .y = 200,
            .width = 500,
            .height = 80,
            .p_child_tree = null,
        },
        &.{
            .p_wnd = list_box.asWnd(), //
            .resource_id = ID_LIST_BOX,
            .str = "listbox",
            .x = 10,
            .y = 300,
            .width = 200,
            .height = 60,
            .p_child_tree = null,
            .user_data = @ptrCast(&guilite.ListBoxData{ .items = &[_][]const u8{ "item1", "item2" }, .selected = 1 }),
        },
        &.{
            .p_wnd = spin_box.asWnd(), //
            .resource_id = ID_SPIN_BOX,
            .str = "spinbox",
            .x = 10,
            .y = 500,
            .width = 100,
            .height = 30,
            .p_child_tree = null,
        },
        &.{
            .p_wnd = table.asWnd(), //
            .resource_id = ID_SPIN_BOX,
            .str = "table",
            .x = 10,
            .y = 540,
            .width = 300,
            .height = 30,
            .p_child_tree = null,
            .user_data = @ptrCast(&guilite.TableData{
                .items = &.{
                    &.{
                        .{
                            .str = "1",
                            .color = guilite.BLACK,
                        },
                        .{
                            .str = "2",
                            .color = guilite.WHITE,
                        },
                    },
                    &.{
                        .{
                            .str = "3",
                            .color = guilite.RED,
                        },
                        .{
                            .str = "4",
                            .color = guilite.RED,
                        },
                    },
                },
            }),
        },
        null,
    };

    spin_box.asWnd().m_font = guilite.Theme.get_font(.FONT_CUSTOM1);
    spin_box.m_bt_down.button.wnd.m_font = guilite.Theme.get_font(.FONT_CUSTOM1);
    spin_box.m_bt_up.button.wnd.m_font = guilite.Theme.get_font(.FONT_CUSTOM1);

    std.log.debug("main list_box:{*} item0:{s}", .{ &list_box, list_box.m_item_array[0] });

    const usize_width = @as(usize, @as(u32, @bitCast(screen_width)));
    const usize_height = @as(usize, @as(u32, @bitCast(screen_height)));
    const fb32: [*]u32 = @ptrCast(@alignCast(fbuf));
    std.log.debug("fb32:{*}", .{fb32});
    for (10..usize_height - 10) |y| {
        for (10..usize_width - 10) |x| {
            fb32[y * usize_width + x] = 0xff_ff_ff_ff;
        }
    }

    std.log.debug("s_desktop_children[0]:{*},s_desktop_children[0].resource_id:{d}", .{ s_desktop_children[0], s_desktop_children[0].?.resource_id });
    var _display: guilite.Display = .{};
    try _display.init2(fbuf, screen_width, screen_height, screen_width, screen_height, color_bytes, 3, null);
    const surface = try _display.alloSurface(.Z_ORDER_LEVEL_1, guilite.Rect.init2(0, 0, screen_width, screen_height));
    surface.set_active(true);

    // try showFont.showFont(allocator, surface);

    surface.draw_line(0, 0, screen_width - 1, 500, guilite.GL_RGB(255, 200, 100), guilite.Z_ORDER_LEVEL_1);
    desktop.asWnd().set_surface(surface);
    try desktop.wnd.connect(null, ID_DESKTOP, null, 0, 0, i16_width, i16_height, &s_desktop_children);

    try desktop.asWnd().show_window();

    // try dialog.open_dialog(true);

    var keyboard = guilite.Keyboard{};

    _ = try keyboard.open_keyboard(edit.asWnd(), ID_KEYBOARD, .STYLE_ALL_BOARD, guilite.WND_CALLBACK.init(&keyboard, &struct {
        fn onclick(kb: *guilite.Keyboard, id: int, param: int) void {
            std.log.debug("onkbclick.onclick keyboard:{*}", .{kb});
            // _ = this;
            _ = id;
            _ = param;
        }
    }.onclick));
    try keyboard.asWnd().show_window();

    // _ = _display.flush_screen(&_display, 0, 0, screen_width, screen_height, @ptrCast(mem_fb), screen_width);
    // _display.fill_rect(&_display, 0, 0, 100, 100, @as(u32, 0xff_00));
    // surface.draw_rect_pos(0, 0, 100, 100, guilite.GL_RGB(200, 0, 0), @intFromEnum(guilite.Z_ORDER_LEVEL.Z_ORDER_LEVEL_1), 10);
    // surface.fill_rect(guilite.Rect{ .m_left = 30, .m_top = 200, .m_right = 400, .m_bottom = 600 }, guilite.GL_RGB(0, 100, 0), 1);
    // try _3d.create_ui(&_display);
    std.log.debug("main end", .{});

    try x11.appLoop();
}

const Desktop = struct {
    wnd: guilite.Wnd = .{
        .m_class = "Desktop",
    },
    pub fn asWnd(this: *Desktop) *guilite.Wnd {
        this.wnd.m_vtable.on_paint = Desktop.on_paint;
        return &this.wnd;
    }
    fn on_paint(this: *guilite.Wnd) !void {
        _ = this;
        std.log.debug("Desktop on paint", .{});
    }
};
