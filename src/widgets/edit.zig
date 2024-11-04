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
    m_str_input: [MAX_EDIT_STRLEN]u8 = std.mem.zeroes([MAX_EDIT_STRLEN]u8),
    m_str: [MAX_EDIT_STRLEN]u8 = std.mem.zeroes([MAX_EDIT_STRLEN]u8),
    var s_keyboard: keyboard.c_keyboard = .{};

    pub fn asWnd(this: *c_edit) *c_wnd {
        return &this.wnd;
    }
    fn get_text(this: *c_edit) []const u8 {
        return this.m_str;
    }
    fn set_text(this: *c_edit, str: []const u8) void {
        // std.log.err("edit set_text str len:{d}", .{str.len});
        api.strcpy(&this.m_str, str);
        // std.log.err("edit set_text m_str strlen:{d}", .{api.strlen(&this.m_str)});
    }
    fn set_keyboard_style(this: *c_edit, kb_sytle: keyboard.KEYBOARD_STYLE) void {
        this.m_kb_style = kb_sytle;
    }
    fn on_touch(w: *c_wnd, x: int, y: int, action: wnd.TOUCH_ACTION) void {
        const this: *c_edit = @fieldParentPtr("wnd", w);
        if (action == .TOUCH_DOWN) {
            this.on_touch_down(x, y);
        } else {
            this.on_touch_up(x, y);
        }
    }
    fn on_touch_down(this: *c_edit, x: int, y: int) void {
        var kb_rect_relate_2_edit_parent: c_rect = undefined;
        const keyboardWnd = s_keyboard.asWnd();
        keyboardWnd.get_wnd_rect(&kb_rect_relate_2_edit_parent);

        const thisWnd = &this.wnd;
        kb_rect_relate_2_edit_parent.m_left += thisWnd.m_wnd_rect.m_left;
        kb_rect_relate_2_edit_parent.m_right += thisWnd.m_wnd_rect.m_left;
        kb_rect_relate_2_edit_parent.m_top += thisWnd.m_wnd_rect.m_top;
        kb_rect_relate_2_edit_parent.m_bottom += thisWnd.m_wnd_rect.m_top;

        if (thisWnd.m_wnd_rect.pt_in_rect(x, y)) { //click edit box
            if (.STATUS_NORMAL == thisWnd.m_status) {
                if (thisWnd.m_parent) |m_parent| {
                    _ = m_parent.set_child_focus(thisWnd);
                }
            }
        } else if (kb_rect_relate_2_edit_parent.pt_in_rect(x, y)) { //click key board
            // 	c_wnd::on_touch(x, y, TOUCH_DOWN);
            thisWnd.on_touch(x, y, .TOUCH_DOWN);
        } else {
            if (.STATUS_PUSHED == thisWnd.m_status) {
                thisWnd.m_status = .STATUS_FOCUSED;
                thisWnd.on_paint();
            }
        }
    }
    fn on_touch_up(this: *c_edit, x: int, y: int) void {
        const thisWnd = &this.wnd;
        if (.STATUS_FOCUSED == thisWnd.m_status) {
            thisWnd.m_status = .STATUS_PUSHED;
            thisWnd.on_paint();
        } else if (.STATUS_PUSHED == thisWnd.m_status) {
            if (thisWnd.m_wnd_rect.pt_in_rect(x, y)) { //click edit box
                thisWnd.m_status = .STATUS_FOCUSED;
                thisWnd.on_paint();
            } else {
                thisWnd.on_touch(x, y, .TOUCH_UP);
            }
        }
    }
    fn on_navigate(w: *c_wnd, key: wnd.NAVIGATION_KEY) void {
        switch (key) {
            .NAV_ENTER => {
                if (w.m_status == .STATUS_PUSHED) {
                    s_keyboard.asWnd().on_navigate(key);
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
                    // m_surface.fill_rect(rect, api.GL_RGB(255, 0, 0), this.m_z_order);
                    m_surface.fill_rect(rect, c_theme.get_color(.COLOR_WND_NORMAL), this.m_z_order);
                    if (this.m_parent) |m_parent| {
                        c_word.draw_string_in_rect(m_surface, m_parent.get_z_order(), &edit.m_str, rect, this.m_font, this.m_font_color, c_theme.get_color(.COLOR_WND_NORMAL), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                    } else {
                        api.ASSERT(false);
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
                        if (this.m_parent) |m_parent| {
                            c_word.draw_string_in_rect(m_surface, m_parent.get_z_order(), m_str, rect, this.m_font, this.m_font_color, c_theme.get_color(.COLOR_WND_FOCUS), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                        } else {
                            api.ASSERT(false);
                        }
                    }
                }
            },
            .STATUS_PUSHED => {
                if ((s_keyboard.asWnd().get_attr() & wnd.ATTR_VISIBLE) != wnd.ATTR_VISIBLE) {
                    this.m_attr = @enumFromInt(wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS | wnd.ATTR_PRIORITY);
                    _ = s_keyboard.open_keyboard(this, IDD_KEY_BOARD, edit.m_kb_style, wnd.WND_CALLBACK.init(edit, c_edit.on_key_board_click));
                }
                if (this.m_surface) |m_surface| {
                    if (this.m_parent) |m_parent| {
                        m_surface.fill_rect(rect, c_theme.get_color(.COLOR_WND_PUSHED), m_parent.get_z_order());
                        m_surface.draw_rect(rect, c_theme.get_color(.COLOR_WND_BORDER), m_parent.get_z_order(), 2);
                        if (api.strlen(edit.m_str_input[0..]) > 0) {
                            c_word.draw_string_in_rect(m_surface, m_parent.get_z_order(), edit.m_str_input[0..], rect, this.m_font, this.m_font_color, c_theme.get_color(.COLOR_WND_PUSHED), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                        } else {
                            if (this.m_str) |m_str| {
                                c_word.draw_string_in_rect(m_surface, m_parent.get_z_order(), m_str, rect, this.m_font, this.m_font_color, c_theme.get_color(.COLOR_WND_PUSHED), api.ALIGN_HCENTER | api.ALIGN_VCENTER);
                            }
                        }
                    } else {
                        api.ASSERT(false);
                    }
                }
            },
            else => {
                api.ASSERT(false);
            },
        }
    }
    fn on_key_board_click(this: *c_edit, id: int, param: int) void {
        // _ = this;
        _ = id;
        // _ = param;
        const thisWnd = this.asWnd();
        const clickStatus: keyboard.CLICK_STATUS = @enumFromInt(param);
        switch (clickStatus) {
            .CLICK_CHAR => {
                api.strcpy(&this.m_str_input, s_keyboard.get_str());
                thisWnd.on_paint();
            },
            .CLICK_ENTER => {
                if (api.strlen(&this.m_str_input) > 0) {
                    @memcpy(&this.m_str, &this.m_str_input);
                }
                thisWnd.m_status = .STATUS_FOCUSED;
                thisWnd.on_paint();
            },
            .CLICK_ESC => {
                // memset(m_str_input, 0, sizeof(m_str_input));
                @memset(&this.m_str_input, 0);
                thisWnd.m_status = .STATUS_FOCUSED;
                thisWnd.on_paint();
            },
        }
    }
    fn pre_create_wnd(this: *c_wnd) void {
        this.m_attr = @enumFromInt(wnd.ATTR_VISIBLE | wnd.ATTR_FOCUS);
        const edit: *c_edit = @fieldParentPtr("wnd", this);
        edit.m_kb_style = .STYLE_ALL_BOARD;
        this.m_font = c_theme.get_font(.FONT_CUSTOM1);
        this.m_font_color = c_theme.get_color(.COLOR_WND_FONT);
        this.m_status = .STATUS_PUSHED;
        if (this.m_str) |str| {
            const strlen = api.strlen(str);
            edit.set_text(str[0..strlen]);
        }
    }
};
