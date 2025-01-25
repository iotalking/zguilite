const std = @import("std");
const zguilite = @import("zguilite");
const _3d = @import("./3d.zig");
const X11 = @import("x11");
const freetype = @import("freetype");

const wave_demo = X11.wave_demo;
const int = c_int;
const uint = c_uint;

fn loadResource() !void {
    try freetype.FreetypeOperator.init();
    zguilite.fontOperator = freetype.FreetypeOperator.ToFontOperator();

    // _ = zguilite.Theme.add_font(.FONT_DEFAULT, @ptrCast(@constCast(&zguilite.Consolas_24B.Consolas_24B)));
    var args = std.process.args();
    _ = args.skip();
    var fontPath:[:0]const u8 = "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc";
    if(args.next())|next|{
        std.log.debug("args{s}",.{next});
        fontPath = next;
    }
    
    _ = zguilite.Theme.add_font(.FONT_DEFAULT, @ptrCast(@constCast(try freetype.FreetypeOperator.set_font(fontPath,32,32))));
    _ = zguilite.Theme.add_font(.FONT_CUSTOM1, @ptrCast(@constCast(try freetype.FreetypeOperator.set_font(fontPath,28,28))));
    _ = zguilite.Theme.add_color(.COLOR_WND_FONT, zguilite.GL_RGB(255, 255, 255));
    _ = zguilite.Theme.add_color(.COLOR_WND_NORMAL, zguilite.GL_RGB(59, 75, 94));
    _ = zguilite.Theme.add_color(.COLOR_WND_PUSHED, zguilite.GL_RGB(33, 42, 53));
    _ = zguilite.Theme.add_color(.COLOR_WND_FOCUS, zguilite.GL_RGB(43, 118, 219));
    _ = zguilite.Theme.add_color(.COLOR_WND_BORDER, zguilite.GL_RGB(46, 59, 73));
}

pub fn main() !void {
    try loadResource();

    var app = X11{};

    const screen_width: int = 1024;
    const screen_height: int = 800;
    var color_bytes: uint = 0;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const i16_height: i16 = @truncate(screen_height);
    const i16_width: i16 = @truncate(screen_width);
    const frameBuffer = try app.init(allocator,"main", screen_width, screen_height, &color_bytes);
    defer app.deinit();
    const fbuf: [*]u8 = frameBuffer.ptr;

    var desktop = Desktop{};
    var btn: zguilite.Button = zguilite.Button{};
    var label: zguilite.Label = zguilite.Label{};
    var edit: zguilite.Edit = zguilite.Edit{};
    var list_box: zguilite.ListBox = zguilite.ListBox{};
    var dialog = zguilite.Dialog{};
    var spin_box: zguilite.SpinBox = zguilite.SpinBox{};
    var table: zguilite.Table = zguilite.Table{};
    var wave_ctrl = zguilite.WaveCtrl.init(allocator);
    defer wave_ctrl.deinit();
    var wave_ctrl2 = zguilite.WaveCtrl.init(allocator);
    defer wave_ctrl2.deinit();
    var wave_ctrl3 = zguilite.WaveCtrl.init(allocator);
    defer wave_ctrl3.deinit();

    wave_demo.wave1 = &wave_ctrl;
    wave_demo.wave2 = &wave_ctrl2;
    wave_demo.wave3 = &wave_ctrl3;
    try wave_demo.init();

    const ID_BTN = 1;
    const ID_DESKTOP = 2;
    const ID_LABEL = 3;
    const ID_DIALOG = 4;
    const ID_KEYBOARD = 5;
    const ID_EDIT = 6;
    const ID_LIST_BOX = 7;
    const ID_SPIN_BOX = 8;
    const ID_TABLE = 9;
    const ID_WAVE_CTRL = 10;
    const ID_WAVE_CTRL2 = 11;
    const ID_WAVE_CTRL3 = 13;

    // _ = btn;
    var s_desktop_children = [_]?*const zguilite.WND_TREE{
        &.{
            .p_wnd = dialog.asWnd(), //
            .resource_id = ID_DIALOG,
            .str = "千里辞",
            .x = 10,
            .y = 10,
            .width = 600,
            .height = 80,
            .p_child_tree = null,
        },
        &.{
            .p_wnd = btn.asWnd(), //
            .resource_id = ID_BTN,
            .str = "吴朝辞",
            .x = 10,
            .y = 10,
            .width = 600,
            .height = 80,
            .p_child_tree = null,
        },
        &.{
            .p_wnd = label.asWnd(), //
            .resource_id = ID_LABEL,
            .str = "123朝辞白帝彩云间千里江陵一日还两岸猿声啼不住轻舟已过万重山",
            .x = 10,
            .y = 100,
            .width = 900,
            .height = 80,
            .p_child_tree = null,
        },
        &.{
            .p_wnd = edit.asWnd(), //
            .resource_id = ID_EDIT,
            .str = "edit",
            .x = 10,
            .y = 200,
            .width = 600,
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
            .user_data = @ptrCast(&zguilite.ListBoxData{ .items = &[_][]const u8{ "item1", "item2" }, .selected = 1 }),
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
            .resource_id = ID_TABLE,
            .str = "table",
            .x = 300,
            .y = 500,
            .width = 500,
            .height = 100,
            .p_child_tree = null,
            .user_data = @ptrCast(&zguilite.TableData{
                .borderColor = zguilite.COLORS.RED,
                .borderSize = 5,
                .bgColor = zguilite.GL_ARGB(255, 0, 0, 0),
                .items = &.{
                    &.{
                        .{
                            .str = "1",
                            .color = zguilite.COLORS.BLACK,
                            .w = 60,
                            .h = 40,
                        },
                        .{
                            .str = "2",
                            .color = zguilite.COLORS.RED,
                            .w = 40,
                            .h = 40,
                        },
                        .{
                            .str = "3",
                            .color = zguilite.COLORS.BLACK,
                            .w = 60,
                            .h = 40,
                        },
                        .{
                            .str = "4",
                            .color = zguilite.COLORS.RED,
                            .w = 40,
                            .h = 40,
                        },
                        .{
                            .str = "5",
                            .color = zguilite.COLORS.BLACK,
                            .w = 60,
                            .h = 40,
                        },
                        .{
                            .str = "6",
                            .color = zguilite.COLORS.RED,
                            .w = 40,
                            .h = 40,
                        },
                        .{
                            .str = "7",
                            .color = zguilite.COLORS.BLACK,
                            .w = 60,
                            .h = 40,
                        },
                        .{
                            .str = "8",
                            .color = zguilite.COLORS.RED,
                            .w = 100,
                            .h = 40,
                        },
                    },
                    &.{
                        .{
                            .str = "3",
                            .color = zguilite.COLORS.RED,
                            .w = 30,
                            .h = 40,
                        },
                        .{
                            .str = "4",
                            .color = zguilite.GL_ARGB(100, 0, 255, 255),
                            .w = 40,
                            .h = 60,
                        },
                    },
                },
            }),
        },
        &.{
            .p_wnd = wave_ctrl.asWnd(), //
            .resource_id = ID_WAVE_CTRL,
            .str = "wavectrl",
            .x = 300,
            .y = 300,
            .width = 400,
            .height = 40,
            .p_child_tree = null,
        },
        &.{
            .p_wnd = wave_ctrl2.asWnd(), //
            .resource_id = ID_WAVE_CTRL2,
            .str = "wavectrl",
            .x = 300,
            .y = 350,
            .width = 400,
            .height = 40,
            .p_child_tree = null,
        },
        &.{
            .p_wnd = wave_ctrl3.asWnd(), //
            .resource_id = ID_WAVE_CTRL3,
            .str = "wavectrl3",
            .x = 300,
            .y = 400,
            .width = 400,
            .height = 100,
            .p_child_tree = null,
        },
        null,
    };

    spin_box.asWnd().m_font = zguilite.Theme.get_font(.FONT_CUSTOM1);
    spin_box.m_bt_down.button.wnd.m_font = zguilite.Theme.get_font(.FONT_CUSTOM1);
    spin_box.m_bt_up.button.wnd.m_font = zguilite.Theme.get_font(.FONT_CUSTOM1);

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
    var _display: zguilite.Display = .{};
    try _display.init2(fbuf, screen_width, screen_height, screen_width, screen_height, color_bytes, 3, null);
    const surface = try _display.allocSurface(.Z_ORDER_LEVEL_1, zguilite.Rect.init2(0, 0, screen_width, screen_height));
    surface.set_active(true);

    // try showFont.showFont(allocator, surface);

    surface.draw_line(0, 0, screen_width - 1, 500, zguilite.GL_RGB(255, 200, 100), zguilite.Z_ORDER_LEVEL_1);
    desktop.asWnd().set_surface(surface);
    try desktop.wnd.connect(null, ID_DESKTOP, null, 0, 0, i16_width, i16_height, &s_desktop_children);

    try desktop.asWnd().show_window();

    // try dialog.open_dialog(true);

    var keyboard = zguilite.Keyboard{};

    _ = try keyboard.open_keyboard(edit.asWnd(), ID_KEYBOARD, .STYLE_ALL_BOARD, zguilite.WND_CALLBACK.init(&keyboard, &struct {
        fn onclick(kb: *zguilite.Keyboard, id: int, param: int) void {
            std.log.debug("onkbclick.onclick keyboard:{*}", .{kb});
            // _ = this;
            _ = id;
            _ = param;
        }
    }.onclick));
    try keyboard.asWnd().show_window();

    // _ = _display.flush_screen(&_display, 0, 0, screen_width, screen_height, @ptrCast(mem_fb), screen_width);
    // _display.fill_rect(&_display, 0, 0, 100, 100, @as(u32, 0xff_00));
    // surface.draw_rect_pos(0, 0, 100, 100, zguilite.GL_RGB(200, 0, 0), @intFromEnum(zguilite.Z_ORDER_LEVEL.Z_ORDER_LEVEL_1), 10);
    // surface.fill_rect(zguilite.Rect{ .m_left = 30, .m_top = 200, .m_right = 400, .m_bottom = 600 }, zguilite.GL_RGB(0, 100, 0), 1);
    // try _3d.create_ui(&_display);
    std.log.debug("main end", .{});
    const idleCallback = zguilite.WND_CALLBACK.init(&app,struct{
        fn onIdle()!void{
            try wave_demo.refrushWaveCtrl();
        }
    }.onIdle);
    app.setIdleCallback(idleCallback);
    try app.loop();
}

const Desktop = struct {
    wnd: zguilite.Wnd = .{
        .m_class = "Desktop",
    },
    pub fn asWnd(this: *Desktop) *zguilite.Wnd {
        this.wnd.m_vtable.on_paint = Desktop.on_paint;
        return &this.wnd;
    }
    fn on_paint(this: *zguilite.Wnd) !void {
        _ = this;
        std.log.debug("Desktop on paint", .{});
    }
};
