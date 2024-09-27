const std = @import("std");
const api = @import("../core/api.zig");
const wnd = @import("../core/wnd.zig");
const resource = @import("../core/resource.zig");
const word = @import("../core/word.zig");
const display = @import("../core/display.zig");
const theme = @import("../core/theme.zig");
const types = @import("../core/types.zig");
const keyboard = @import("./keyboard.zig");
const c_wnd = wnd.c_wnd;
const c_rect = api.c_rect;
const c_word = word.c_word;
const c_theme = theme.c_theme;
const int = types.int;
const uint = types.uint;

pub const MAX_EDIT_STRLEN = 32;
pub const IDD_KEY_BOARD = 0x1;

pub const c_edit = struct {
    wnd: wnd.c_wnd = .{ .m_class = "c_edit", .m_vtable = .{
        .on_paint = c_edit.on_paint,
        .on_focus = c_edit.on_focus,
        .on_kill_focus = c_edit.on_kill_focus,
        .pre_create_wnd = c_edit.pre_create_wnd,
        .on_touch = c_edit.on_touch,
        .on_navigate = c_edit.on_navigate,
    } },
    m_kb_style: keyboard.KEYBOARD_STYLE = .STYLE_ALL_BOARD,
    m_str_input: std.mem.zeroes([MAX_EDIT_STRLEN]u8),
    m_str: std.mem.zeroes([MAX_EDIT_STRLEN]u8),
    var s_keyboard: keyboard.c_keyboard = .{};

    fn get_text(this: *c_edit) []const u8 {
        return this.m_str;
    }
    fn set_text(this: *c_edit, str: []const u8) void {
        const strlen = std.mem.len(@as([*c]const u8, this.m_str));
        const srclen = std.mem.len(@as([*c]const u8, str));
        if (strlen < this.m_str.len) {
            // strcpy(m_str, str);
            std.mem.copyForwards(u8, this.m_str, str[0..srclen :0]);
        }
    }
    fn set_keyboard_style(this: *c_edit, kb_sytle: keyboard.KEYBOARD_STYLE) void {
        this.m_kb_style = kb_sytle;
    }
    fn on_touch(w: *c_wnd, x: int, y: int, action: wnd.TOUCH_ACTION) void {
        _ = w;
        _ = x;
        _ = y;
        _ = action;
    }
    fn on_navigate(w: *c_wnd, key: wnd.NAVIGATION_KEY) void {
        switch (key) {
            .NAV_ENTER => {
                if (w.m_status == .STATUS_PUSHED) {
                    s_keyboard.on_navigate(key);
                } else {
                    w.on_touch(w.m_wnd_rect.m_left, w.m_wnd_rect.m_top, .TOUCH_DOWN);
                    w.on_touch(w.m_wnd_rect.m_left, w.m_wnd_rect.m_top, .TOUCH_UP);
                }
            },
            .NAV_BACKWARD, .NAV_FORWARD => {
                if (w.m_status == .STATUS_PUSHED) {
                    s_keyboard.asWnd().on_navigate(key);
                } else {
                    w.on_navigate(key);
                }
            },
        }
    }
    fn on_kill_focus(this: *c_wnd) void {
        this.m_status = .STATUS_NORMAL;
        this.on_paint();
    }
    fn on_focus(this: *c_wnd) void {
        this.m_status = .STATUS_FOCUSED;
        this.on_paint();
    }
    fn on_paint(this: *c_wnd) void {
        const edit: *c_edit = @fieldParentPtr("wnd", this);
        var rect = c_rect.init();
        var kb_rect = c_rect.init();
        this.get_screen_rect(&rect);
        const keyboard_wnd = s_keyboard.asWnd();
        keyboard_wnd.get_screen_rect(&kb_rect);
        switch (this.m_status) {
            .STATUS_NORMAL => {
                if ((keyboard_wnd.get_attr() & wnd.ATTR_VISIBLE) == wnd.ATTR_VISIBLE) {
                    s_keyboard.close_keyboard();
                    this.m_attr = @enumFromInt(wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS);
                }
                if (this.m_surface) |m_surface| {
                    m_surface.fill_rect(rect, c_theme.get_color(.COLOR_WND_NORMAL), this.m_z_order);
                    if (this.m_str) |m_str| {
                        c_word.draw_string_in_rect(m_surface, this.m_parent.get_z_order(), m_str, rect, this.m_font, this.m_font_color, c_theme.get_color(.COLOR_WND_NORMAL), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                    }
                }
            },
            .STATUS_FOCUSED => {
                if ((keyboard_wnd.get_attr() & wnd.ATTR_VISIBLE) == wnd.ATTR_VISIBLE) {
                    s_keyboard.close_keyboard();
                    this.m_attr = @enumFromInt(wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS);
                }
                if (this.m_surface) |m_surface| {
                    m_surface.fill_rect(rect, c_theme.get_color(.COLOR_WND_FOCUS), this.m_z_order);
                    if (this.m_str) |m_str| {
                        c_word.draw_string_in_rect(m_surface, this.m_parent.get_z_order(), m_str, rect, this.m_font, this.m_font_color, c_theme.get_color(.COLOR_WND_FOCUS), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                    }
                }
            },
            .STATUS_PUSHED => {
                if ((s_keyboard.get_attr() & wnd.ATTR_VISIBLE) != wnd.ATTR_VISIBLE) {
                    this.m_attr = @enumFromInt(wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS | wnd.ATTR_PRIORITY);
                    s_keyboard.open_keyboard(this, IDD_KEY_BOARD, edit.m_kb_style, c_edit.on_key_board_click);
                }
                if (this.m_surface) |m_surface| {
                    m_surface.fill_rect(rect.m_left, rect.m_top, rect.m_right, rect.m_bottom, c_theme.get_color(.COLOR_WND_PUSHED), this.m_parent.get_z_order());
                    m_surface.draw_rect(rect.m_left, rect.m_top, rect.m_right, rect.m_bottom, c_theme.get_color(.COLOR_WND_BORDER), this.m_parent.get_z_order(), 2);
                    if (api.strlen(edit.m_str_input) > 0) {
                        c_word.draw_string_in_rect(m_surface, this.m_parent.get_z_order(), edit.m_str_input, rect, this.m_font, this.m_font_color, c_theme.get_color(.COLOR_WND_PUSHED), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                    } else {
                        c_word.draw_string_in_rect(m_surface, this.m_parent.get_z_order(), this.m_str, rect, this.m_font, this.m_font_color, c_theme.get_color(.COLOR_WND_PUSHED), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                    }
                }
            },
            else => {
                api.ASSERT(false);
            },
        }
    }
    fn on_key_board_click(id: int, param: int) void {
        _ = id;
        _ = param;
    }
    fn pre_create_wnd(this: *c_wnd) void {
        this.m_attr = @enumFromInt(wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS);
        this.m_kb_style = .STYLE_ALL_BOARD;
        this.m_font = c_theme.get_font(.FONT_DEFAULT);
        this.m_font_color = c_theme.get_color(.COLOR_WND_FONT);

        set_text(this.m_str);
    }
};
